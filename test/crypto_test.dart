import 'package:flutter_test/flutter_test.dart';

import 'package:wickly/data/crypto.dart';

// Крипто — чистый Dart, поэтому спокойно гоняется во flutter_tester (без sqflite).
void main() {
  const key =
      '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';

  test('AES-GCM: расшифровка возвращает исходные поля', () async {
    Crypto.instance.init(key);
    final data = {
      'title': 'Секрет',
      'body': 'Личный текст',
      'mood': 4,
      'lat': 55.75,
    };
    final enc = await Crypto.instance.encryptJson(data);

    // В шифртексте нет открытого содержимого.
    expect(enc.contains('Секрет'), false);

    final back = await Crypto.instance.decryptJson(enc);
    expect(back['title'], 'Секрет');
    expect(back['body'], 'Личный текст');
    expect(back['mood'], 4);
    expect(back['lat'], 55.75);
  });

  test('неверный ключ отклоняется (аутентификация GCM)', () async {
    Crypto.instance.init(key);
    final enc = await Crypto.instance.encryptJson({'x': 'y'});

    Crypto.instance.init('f' * 64); // другой ключ
    expect(() => Crypto.instance.decryptJson(enc), throwsA(anything));
  });
}
