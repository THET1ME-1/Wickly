import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wickly/services/photo_crop.dart';

/// Кадр 2×1: левая половина красная, правая синяя.
Uint8List _leftRedRightBlue() {
  final image = img.Image(width: 2, height: 1);
  image.setPixelRgb(0, 0, 255, 0, 0);
  image.setPixelRgb(1, 0, 0, 0, 255);
  return Uint8List.fromList(img.encodePng(image));
}

({int r, int g, int b}) _pixel(Uint8List jpeg, int x, int y) {
  final decoded = img.decodeImage(jpeg)!;
  final p = decoded.getPixel(x, y);
  return (r: p.r.toInt(), g: p.g.toInt(), b: p.b.toInt());
}

void main() {
  test('Без поворота кадр остаётся как был', () {
    final out = cropPhoto(CropJob(
      bytes: _leftRedRightBlue(),
      quarterTurns: 0,
      left: 0,
      top: 0,
      width: 1,
      height: 1,
    ))!;
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, 2);
    expect(decoded.height, 1);
    expect(_pixel(out, 0, 0).r, greaterThan(200));
    expect(_pixel(out, 1, 0).b, greaterThan(200));
  });

  // Поворот на четверть по часовой уводит левую половину наверх — так же, как
  // RotatedBox(quarterTurns: 1) крутит картинку в самом листе. Если пакет
  // повернёт в другую сторону, обрезка уедет мимо того, что человек видел.
  test('Четверть по часовой поднимает левую половину наверх', () {
    final out = cropPhoto(CropJob(
      bytes: _leftRedRightBlue(),
      quarterTurns: 1,
      left: 0,
      top: 0,
      width: 1,
      height: 1,
    ))!;
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, 1);
    expect(decoded.height, 2);
    expect(_pixel(out, 0, 0).r, greaterThan(200), reason: 'сверху красное');
    expect(_pixel(out, 0, 1).b, greaterThan(200), reason: 'снизу синее');
  });

  test('Прямоугольник берёт только свою часть кадра', () {
    final out = cropPhoto(CropJob(
      bytes: _leftRedRightBlue(),
      quarterTurns: 0,
      left: 0.5,
      top: 0,
      width: 0.5,
      height: 1,
    ))!;
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, 1);
    expect(_pixel(out, 0, 0).b, greaterThan(200), reason: 'осталась синяя');
  });

  test('Прямоугольник за границей кадра не даёт пустой полосы', () {
    final out = cropPhoto(CropJob(
      bytes: _leftRedRightBlue(),
      quarterTurns: 0,
      left: 0.9,
      top: 0,
      width: 0.5, // вылезает за правый край
      height: 1,
    ))!;
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, greaterThan(0));
    expect(decoded.width, lessThanOrEqualTo(2));
  });

  test('Незнакомый формат не роняет обрезку', () {
    final out = cropPhoto(CropJob(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      quarterTurns: 0,
      left: 0,
      top: 0,
      width: 1,
      height: 1,
    ));
    expect(out, isNull);
  });
}
