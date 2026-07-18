import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Что вырезать из снимка: поворот и прямоугольник в пикселях уже
/// **повёрнутого** кадра — ровно то, что человек видел в рамке.
class CropJob {
  final Uint8List bytes;

  /// Повороты на 90° по часовой, 0..3.
  final int quarterTurns;

  /// Прямоугольник в долях повёрнутого кадра (0..1) — не в пикселях, чтобы
  /// расчёт не зависел от того, какого размера снимок пришёл.
  final double left;
  final double top;
  final double width;
  final double height;

  /// Ширина результата. Обложку показываем на всю ширину экрана, дальше
  /// растить бессмысленно: вес растёт, видно не станет.
  final int outWidth;

  const CropJob({
    required this.bytes,
    required this.quarterTurns,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.outWidth = 1600,
  });
}

/// Режет снимок по [job]. Возвращает JPEG или null, если формат незнаком.
///
/// Считает на голом Dart через пакет `image`, поэтому уезжает в `compute` и не
/// морозит кадр: на снимке с телефона поворот и обрезка занимают заметное время.
Uint8List? cropPhoto(CropJob job) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(job.bytes);
  } catch (_) {
    // На обрезанном или чужом файле декодер не возвращает null, а лезет за
    // границу буфера и бросает. Обложка не стоит упавшего листа.
    return null;
  }
  if (decoded == null) return null;

  final turns = job.quarterTurns % 4;
  final rotated =
      turns == 0 ? decoded : img.copyRotate(decoded, angle: turns * 90);

  // Доли → пиксели. Прямоугольник обязан остаться внутри кадра: за границей
  // copyCrop дорисовывает пустоту, и у обложки появляется чёрная полоса.
  final x = (job.left * rotated.width).round().clamp(0, rotated.width - 1);
  final y = (job.top * rotated.height).round().clamp(0, rotated.height - 1);
  final w = (job.width * rotated.width).round().clamp(1, rotated.width - x);
  final h = (job.height * rotated.height).round().clamp(1, rotated.height - y);

  final cropped = img.copyCrop(rotated, x: x, y: y, width: w, height: h);
  final sized = cropped.width > job.outWidth
      ? img.copyResize(cropped, width: job.outWidth)
      : cropped;

  return Uint8List.fromList(img.encodeJpg(sized, quality: 88));
}
