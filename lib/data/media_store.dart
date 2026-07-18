import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;

import 'crypto.dart';

/// Файлы вложений на диске.
///
/// Каждый файл лежит **зашифрованным** (AES-GCM тем же ключом, что и записи):
/// даже если кто-то доберётся до каталога приложения, там будет шум. Имя файла
/// — хэш содержимого, поэтому одинаковые фото не дублируются.
///
/// Для показа файл расшифровывается в память ([read]) либо во временный
/// каталог ([materialize]) — плеерам и `video_player` нужен реальный путь.
class MediaStore {
  MediaStore._();
  static final MediaStore instance = MediaStore._();

  Directory? _dir;
  Directory? _tmp;

  /// Каталоги приходят снаружи (из `main`, через `path_provider`), чтобы сам
  /// склад оставался чистым Dart и проверялся в `tool/db_smoke.dart`.
  void configure({required String supportDir, required String tempDir}) {
    _dir = Directory('$supportDir/media')..createSync(recursive: true);
    _tmp = Directory('$tempDir/wickly_media')..createSync(recursive: true);
  }

  Future<Directory> _mediaDir() async => _dir!;

  Future<Directory> _tmpDir() async => _tmp!;

  Future<String> path(String name) async => '${(await _mediaDir()).path}/$name';

  /// Кладёт байты в хранилище зашифрованными. Возвращает имя файла.
  Future<String> put(Uint8List bytes, {required String ext}) async {
    final name = '${hash.sha256.convert(bytes).toString().substring(0, 32)}.$ext';
    final file = File(await path(name));
    if (!file.existsSync()) {
      await file.writeAsBytes(await Crypto.instance.encryptBytes(bytes));
    }
    return name;
  }

  /// Забирает файл из системы (камера, галерея, диктофон) в хранилище.
  Future<String> putFile(File source, {String? ext}) async {
    final bytes = await source.readAsBytes();
    final dotted = source.path.split('.').last.toLowerCase();
    return put(bytes, ext: ext ?? (dotted.length <= 5 ? dotted : 'bin'));
  }

  /// Расшифрованные байты вложения (для картинок — прямо в `Image.memory`).
  Future<Uint8List?> read(String name) async {
    final file = File(await path(name));
    if (!file.existsSync()) return null;
    try {
      return await Crypto.instance.decryptBytes(await file.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  /// Кладёт расшифрованную копию во временный каталог и отдаёт путь —
  /// для плееров, «поделиться» и экспорта. Временный каталог чистится
  /// системой и вручную через [clearTemp].
  Future<String?> materialize(String name) async {
    final bytes = await read(name);
    if (bytes == null) return null;
    final out = File('${(await _tmpDir()).path}/$name');
    if (!out.existsSync() || out.lengthSync() != bytes.length) {
      await out.writeAsBytes(bytes);
    }
    return out.path;
  }

  Future<void> deleteFile(String name) async {
    final file = File(await path(name));
    if (file.existsSync()) await file.delete();
    final tmp = File('${(await _tmpDir()).path}/$name');
    if (tmp.existsSync()) await tmp.delete();
  }

  /// Стирает расшифрованные копии — вызываем при блокировке дневника.
  Future<void> clearTemp() async {
    final dir = await _tmpDir();
    if (dir.existsSync()) {
      for (final f in dir.listSync()) {
        try {
          f.deleteSync(recursive: true);
        } catch (_) {
          // Файл может быть занят плеером — не повод падать.
        }
      }
    }
  }

  /// Сколько места занимают вложения (для экрана «Экспорт и бэкап»).
  Future<int> totalBytes() async {
    final dir = await _mediaDir();
    if (!dir.existsSync()) return 0;
    var sum = 0;
    for (final f in dir.listSync()) {
      if (f is File) sum += f.lengthSync();
    }
    return sum;
  }

  /// Имена всех файлов хранилища — для бэкапа и уборки сирот.
  Future<List<String>> listNames() async {
    final dir = await _mediaDir();
    if (!dir.existsSync()) return const [];
    return dir.listSync().whereType<File>().map((f) {
      final p = f.path;
      return p.substring(p.lastIndexOf(Platform.pathSeparator) + 1);
    }).toList();
  }
}
