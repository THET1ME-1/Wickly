import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wickly/services/image_prep.dart';

Uint8List jpeg(int width, int height) {
  final image = img.Image(width: width, height: height);
  // Ровная заливка сжимается в считаные килобайты и декодируется быстро —
  // тесту важны размеры, а не содержимое кадра.
  img.fill(image, color: img.ColorRgb8(120, 90, 40));
  return Uint8List.fromList(img.encodeJpg(image, quality: 80));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('размеры', () {
    test('читаются из заголовка', () async {
      expect(await ImagePrep.size(jpeg(1600, 1200)), (1600, 1200));
    });

    test('у мусора размеров нет', () async {
      final junk = Uint8List.fromList(List.filled(2048, 7));
      expect(await ImagePrep.size(junk), isNull);
    });
  });

  group('превью', () {
    test('альбомный кадр ужимается по ширине', () async {
      final thumb = await ImagePrep.thumb(jpeg(1600, 1200), 480);
      expect(thumb, isNotNull);
      final decoded = img.decodeImage(thumb!)!;
      expect(decoded.width, 480);
      expect(decoded.height, 360);
    });

    test('портретный кадр ужимается по высоте', () async {
      final thumb = await ImagePrep.thumb(jpeg(1200, 1600), 480);
      final decoded = img.decodeImage(thumb!)!;
      expect(decoded.height, 480);
      expect(decoded.width, 360);
    });

    test('мелкому кадру превью не нужно', () async {
      expect(await ImagePrep.thumb(jpeg(300, 200), 480), isNull);
    });

    test('кадр ровно в сторону превью остаётся без него', () async {
      expect(await ImagePrep.thumb(jpeg(480, 320), 480), isNull);
    });

    test('мусор превью не даёт', () async {
      final junk = Uint8List.fromList(List.filled(2048, 7));
      expect(await ImagePrep.thumb(junk, 480), isNull);
    });
  });
}
