import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../data/media_repository.dart';
import '../data/media_store.dart';
import '../data/system_pause.dart';
import '../models/media.dart';

/// Кладёт фото, видео и рисунки в запись.
///
/// Порядок один на все виды: файл → зашифрованный склад → превью → строка в
/// базе. Исходник из галереи не трогаем и не удаляем: дневник забирает копию.
class MediaService {
  const MediaService._();

  static final _picker = ImagePicker();

  /// Сторона превью. 480 хватает и ленте, и медиа-сетке на плотном экране,
  /// а расшифровывать его на порядок дешевле, чем полный кадр.
  static const _thumbSide = 480;

  /// Фото из галереи (можно несколько) в запись.
  static Future<List<Media>> pickPhotos(String entryId, {int sortFrom = 0}) async {
    // Галерея уводит приложение в фон — иначе на возврате сработает замок.
    final files = await SystemPause.shield(() => _picker.pickMultiImage());
    final out = <Media>[];
    for (var i = 0; i < files.length; i++) {
      final m = await _attachImage(entryId, files[i], sort: sortFrom + i);
      if (m != null) out.add(m);
    }
    return out;
  }

  /// Снимок с камеры.
  static Future<Media?> takePhoto(String entryId, {int sort = 0}) async {
    final file = await SystemPause.shield(
        () => _picker.pickImage(source: ImageSource.camera));
    if (file == null) return null;
    return _attachImage(entryId, file, sort: sort);
  }

  /// Видео из галереи или с камеры.
  static Future<Media?> pickVideo(
    String entryId, {
    ImageSource source = ImageSource.gallery,
    int sort = 0,
  }) async {
    final file =
        await SystemPause.shield(() => _picker.pickVideo(source: source));
    if (file == null) return null;
    final name = await MediaStore.instance.putFile(File(file.path));
    final media = Media.create(
      entryId: entryId,
      kind: MediaKind.video,
      file: name,
      sort: sort,
    );
    await MediaRepository.instance.insert(media);
    return media;
  }

  /// Рисунок от руки — уже готовые байты PNG.
  static Future<Media> attachSketch(
    String entryId,
    Uint8List png, {
    int sort = 0,
  }) async {
    final name = await MediaStore.instance.put(png, ext: 'png');
    final thumb = await _makeThumb(png);
    final media = Media.create(
      entryId: entryId,
      kind: MediaKind.sketch,
      file: name,
      thumb: thumb,
      sort: sort,
    );
    await MediaRepository.instance.insert(media);
    return media;
  }

  /// Аудио-заметка: файл записан диктофоном, лежит во временном каталоге.
  static Future<Media> attachAudio(
    String entryId,
    String path, {
    int? durationMs,
    int sort = 0,
  }) async {
    final source = File(path);
    final name = await MediaStore.instance.putFile(source);
    final media = Media.create(
      entryId: entryId,
      kind: MediaKind.audio,
      file: name,
      durationMs: durationMs,
      sort: sort,
    );
    await MediaRepository.instance.insert(media);
    // Временный файл диктофона больше не нужен: копия уже зашифрована.
    if (source.existsSync()) {
      try {
        await source.delete();
      } catch (_) {
        // Файл держит плеер — уберётся при следующей чистке.
      }
    }
    return media;
  }

  /// Общий путь для картинки: сперва сохранить, потом всё остальное.
  ///
  /// Порядок важен. Раньше фото сначала декодировалось ради размеров и превью,
  /// и на большом снимке с телефона декодер мог не справиться — тогда падало
  /// всё вместе, и фотография не попадала в запись вообще. Теперь снимок
  /// сохраняется первым, а EXIF, размеры и превью считаются по мере
  /// возможности: не вышло — останется фото без превью, а не пустота.
  static Future<Media?> _attachImage(
    String entryId,
    XFile file, {
    required int sort,
  }) async {
    final Uint8List bytes;
    final String name;
    try {
      bytes = await file.readAsBytes();
      name = await MediaStore.instance.put(bytes, ext: _extOf(file.path));
    } catch (_) {
      // Файл не прочитался или диск занят — прикрепить нечего.
      return null;
    }

    final exif = await _readExif(bytes);
    final thumb = await _makeThumb(bytes);
    final size = _sizeOf(bytes);

    final media = Media.create(
      entryId: entryId,
      kind: MediaKind.photo,
      file: name,
      thumb: thumb,
      sort: sort,
      takenAt: exif.takenAt,
      lat: exif.lat,
      lon: exif.lon,
      width: size?.$1,
      height: size?.$2,
    );
    await MediaRepository.instance.insert(media);
    return media;
  }

  /// Расширение файла. Путь без точки дал бы имя с косыми чертами, и запись
  /// на диск упала бы на ровном месте.
  static String _extOf(String path) {
    final name = path.split(Platform.pathSeparator).last;
    if (!name.contains('.')) return 'jpg';
    final ext = name.split('.').last.toLowerCase();
    return RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext) ? ext : 'jpg';
  }

  /// Предел на число пикселей, которое соглашаемся раскодировать (~60 Мп).
  /// «Декомпресс-бомба» — маленький файл, разворачивающийся в гигапиксельный
  /// кадр, — иначе кладёт процесс на превью/размерах. Размеры берём из
  /// заголовка, не разворачивая всё изображение.
  static const _maxPixels = 60 * 1000 * 1000;

  static bool _tooLarge(Uint8List bytes) {
    try {
      final info = img.findDecoderForData(bytes)?.startDecode(bytes);
      if (info == null) return false; // формат неизвестен — решит сам decode
      return info.width * info.height > _maxPixels;
    } catch (_) {
      return false;
    }
  }

  /// Размеры кадра. Формат может оказаться незнакомым (HEIC с айфона) —
  /// тогда сетка возьмёт пропорции по умолчанию.
  static (int, int)? _sizeOf(Uint8List bytes) {
    if (_tooLarge(bytes)) return null;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return (decoded.width, decoded.height);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _makeThumb(Uint8List bytes) async {
    if (_tooLarge(bytes)) return null;
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      final side = decoded.width >= decoded.height ? decoded.width : decoded.height;
      if (side <= _thumbSide) return null; // мелкое превью не нужно
      final resized = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: _thumbSide)
          : img.copyResize(decoded, height: _thumbSide);
      return MediaStore.instance.put(
        Uint8List.fromList(img.encodeJpg(resized, quality: 82)),
        ext: 'jpg',
      );
    } catch (_) {
      return null;
    }
  }

  /// Где и когда снято фото — из EXIF самого файла.
  static Future<_Exif> _readExif(Uint8List bytes) async {
    try {
      final tags = await readExifFromBytes(bytes);
      if (tags.isEmpty) return const _Exif();
      return _Exif(
        takenAt: _exifDate(tags['EXIF DateTimeOriginal']?.printable ??
            tags['Image DateTime']?.printable),
        lat: _exifCoord(
          tags['GPS GPSLatitude'],
          tags['GPS GPSLatitudeRef']?.printable,
        ),
        lon: _exifCoord(
          tags['GPS GPSLongitude'],
          tags['GPS GPSLongitudeRef']?.printable,
        ),
      );
    } catch (_) {
      return const _Exif();
    }
  }

  /// EXIF пишет дату как «2026:07:17 21:10:33».
  static DateTime? _exifDate(String? raw) {
    if (raw == null || raw.length < 19) return null;
    final normalized =
        '${raw.substring(0, 10).replaceAll(':', '-')}T${raw.substring(11, 19)}';
    return DateTime.tryParse(normalized);
  }

  /// Координаты в EXIF лежат тройкой градус/минута/секунда.
  static double? _exifCoord(IfdTag? tag, String? ref) {
    final values = tag?.values.toList();
    if (values == null || values.length < 3) return null;
    double part(int i) {
      final v = values[i];
      if (v is Ratio) return v.numerator / v.denominator;
      if (v is num) return v.toDouble();
      return 0;
    }

    final degrees = part(0) + part(1) / 60 + part(2) / 3600;
    final negative = ref == 'S' || ref == 'W';
    return negative ? -degrees : degrees;
  }
}

class _Exif {
  final DateTime? takenAt;
  final double? lat;
  final double? lon;
  const _Exif({this.takenAt, this.lat, this.lon});
}
