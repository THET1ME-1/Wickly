import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/services/web_photo_service.dart';

void main() {
  // Кириллица в User-Agent роняла FormatException ещё до отправки запроса, а
  // `catch` в search() её глотал: подбор обложки по теме молча возвращал
  // пустой список всегда. Сторож, чтобы не вернулось.
  test('User-Agent состоит только из печатного ASCII', () {
    expect(
      WebPhotoService.userAgent.codeUnits.every((c) => c >= 0x20 && c < 0x7F),
      isTrue,
      reason: 'не-ASCII в значении заголовка — FormatException при запросе',
    );
  });

  test('Пустая тема не ходит в сеть', () async {
    expect(await WebPhotoService.search('   '), isEmpty);
  });
}
