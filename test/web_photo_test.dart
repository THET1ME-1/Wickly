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

  group('Остаток лимита', () {
    // Заголовки списаны с живого ответа api.openverse.org.
    const live = {
      'x-ratelimit-limit-anon_burst': '20/min',
      'x-ratelimit-available-anon_burst': '19',
      'x-ratelimit-limit-anon_sustained': '200/day',
      'x-ratelimit-available-anon_sustained': '199',
    };

    test('Читается из заголовков, период у потолка отбрасывается', () {
      final quota = WebPhotoService.quotaFrom(live, 200);
      expect(quota.leftThisMinute, 19);
      expect(quota.leftToday, 199);
      expect(quota.perMinute, 20);
      expect(quota.perDay, 200);
      expect(quota.exhausted, isFalse);
      expect(quota.known, isTrue);
      expect(quota.low, isFalse);
    });

    test('Пятая часть дневного бюджета — уже мало', () {
      final quota = WebPhotoService.quotaFrom({
        ...live,
        'x-ratelimit-available-anon_sustained': '40',
      }, 200);
      expect(quota.low, isTrue);
    });

    test('429 — исчерпан', () {
      final quota = WebPhotoService.quotaFrom(live, 429);
      expect(quota.exhausted, isTrue);
      expect(quota.low, isTrue);
    });

    test('Без заголовков показывать нечего', () {
      final quota = WebPhotoService.quotaFrom(const {}, 200);
      expect(quota.known, isFalse);
      expect(quota.leftToday, -1);
    });
  });

  // Анонимному запросу Openverse отдаёт максимум 20 снимков: page_size=21
  // возвращает 401, а не урезанный список.
  test('Потолок страницы — 20', () {
    expect(WebPhotoService.maxPageSize, 20);
    expect(30.clamp(1, WebPhotoService.maxPageSize), 20);
  });
}
