// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wickly/widgets/photo_crop_sheet.dart';

import 'harness.dart';

/// Снимок-подопытный: широкий кадр в тёплую полоску, чтобы на снимке экрана
/// было видно и саму картинку, и то, как она села в рамку 3:2.
Uint8List _stripes() {
  final image = img.Image(width: 1200, height: 500);
  for (var x = 0; x < image.width; x++) {
    for (var y = 0; y < image.height; y++) {
      final band = (x ~/ 100) % 2 == 0;
      image.setPixelRgb(
        x,
        y,
        band ? 198 : 122,
        band ? 134 : 88,
        band ? 62 : 48,
      );
    }
  }
  return Uint8List.fromList(img.encodeJpg(image));
}

void main() {
  testWidgets('Кадрирование обложки', (tester) async {
    final bytes = _stripes();
    await Harness.shoot(
      tester,
      'photo_crop',
      // В приложении Material приходит от самого нижнего листа; на стенде его
      // надо дать руками, иначе Slider не строится.
      () => Scaffold(body: PhotoCropSheet(bytes: bytes)),
      // Картинки в тестах не декодируются сами: асинхронность поддельная.
      // Даём живую очередь и прогреваем кэш, иначе на снимке останется
      // крутилка над пустой рамкой и проверять будет нечего.
      afterPump: (t) async {
        final ctx = t.element(find.byType(PhotoCropSheet));
        await t.runAsync(() async {
          await precacheImage(MemoryImage(bytes), ctx);
          await Future<void>.delayed(const Duration(milliseconds: 120));
        });
        await t.pump();
      },
    );
  });
}
