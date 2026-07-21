import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

/// Разбор снимка перед тем, как положить его в запись: размеры и превью.
///
/// Обе задачи решает системный декодер, а не разбор на Dart. Раньше каждая
/// фотография разворачивалась в память целиком дважды — один раз ради ширины
/// с высотой, второй ради превью, — и кадр с телефона отнимал около трёх
/// секунд главного потока. Пачка из десятка снимков вешала редактор почти на
/// полминуты, и человек видел не «идёт загрузка», а замерший экран.
///
/// Теперь размеры читаются из заголовка, а превью декодируется сразу
/// уменьшенным: система разворачивает кадр в нужную сторону, минуя полный.
class ImagePrep {
  ImagePrep._();

  /// Предел на число пикселей, которое соглашаемся разворачивать (~60 Мп).
  /// «Декомпресс-бомба» — маленький файл, разворачивающийся в гигапиксельный
  /// кадр, — иначе кладёт процесс.
  static const _maxPixels = 60 * 1000 * 1000;

  /// Ширина и высота кадра из заголовка файла.
  ///
  /// Формат может оказаться незнакомым (HEIC с айфона) — тогда размеров нет,
  /// и сетка возьмёт пропорции по умолчанию.
  static Future<(int, int)?> size(Uint8List bytes) async {
    final d = await _describe(bytes);
    if (d == null) return null;
    final size = (d.width, d.height);
    d.dispose();
    return size;
  }

  /// Превью со стороной [side] в JPEG. `null`, если кадр и так мелкий,
  /// формат незнаком или картинка неправдоподобно велика.
  static Future<Uint8List?> thumb(Uint8List bytes, int side) async {
    final d = await _describe(bytes);
    if (d == null) return null;

    final width = d.width;
    final height = d.height;
    if (width * height > _maxPixels || (width <= side && height <= side)) {
      d.dispose();
      return null;
    }

    ui.Image? frame;
    try {
      final landscape = width >= height;
      final codec = await d.instantiateCodec(
        targetWidth: landscape ? side : null,
        targetHeight: landscape ? null : side,
      );
      frame = (await codec.getNextFrame()).image;
      codec.dispose();

      final raw = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (raw == null) return null;
      // Кадр уже уменьшен, так что сжатие здесь стоит десяток миллисекунд.
      final small = img.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: raw.buffer,
        numChannels: 4,
      );
      return Uint8List.fromList(img.encodeJpg(small, quality: 82));
    } catch (_) {
      return null;
    } finally {
      frame?.dispose();
      d.dispose();
    }
  }

  /// Заголовок кадра. Вызывающий обязан позвать `dispose`.
  static Future<ui.ImageDescriptor?> _describe(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return await ui.ImageDescriptor.encoded(buffer);
    } catch (_) {
      return null;
    } finally {
      buffer?.dispose();
    }
  }
}
