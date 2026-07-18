import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/services/stats_service.dart';

Entry _at(DateTime d, {int? mood, String? weather}) =>
    Entry.create(journalId: 'j', entryDate: d, mood: mood)
        .copyWith(weather: weather);

void main() {
  _trackerCorrelationTests();
  final today = DateTime(2026, 7, 18);

  test('Серия считается назад от сегодня', () {
    final entries = [
      _at(today),
      _at(today.subtract(const Duration(days: 1))),
      _at(today.subtract(const Duration(days: 2))),
      // разрыв на 3-м дне
      _at(today.subtract(const Duration(days: 5))),
    ];
    final s = StatsService.streak(entries, now: today);
    expect(s.current, 3);
    expect(s.writtenToday, true);
  });

  test('Серия держится, если сегодня ещё не писал', () {
    final entries = [
      _at(today.subtract(const Duration(days: 1))),
      _at(today.subtract(const Duration(days: 2))),
    ];
    final s = StatsService.streak(entries, now: today);
    expect(s.current, 2);
    expect(s.writtenToday, false);
  });

  test('Серия рвётся, если пропущен и вчерашний день', () {
    final entries = [_at(today.subtract(const Duration(days: 2)))];
    expect(StatsService.streak(entries, now: today).current, 0);
  });

  test('Лучшая серия находится в прошлом', () {
    final entries = [
      for (var i = 10; i <= 15; i++)
        _at(today.subtract(Duration(days: i))),
      _at(today),
    ];
    final s = StatsService.streak(entries, now: today);
    expect(s.current, 1);
    expect(s.best, 6);
  });

  test('Несколько записей за день дают одно настроение дня', () {
    final entries = [
      _at(DateTime(2026, 7, 18, 9), mood: 3),
      _at(DateTime(2026, 7, 18, 21), mood: 5),
    ];
    final byDay = StatsService.moodByDay(entries);
    expect(byDay.length, 1);
    expect(byDay.values.first, 4);
  });

  test('Сводка: среднее, охват и рост против прошлого периода', () {
    final entries = [
      // текущая неделя, среднее 4
      _at(DateTime(2026, 7, 15), mood: 4),
      _at(DateTime(2026, 7, 16), mood: 4),
      // прошлая неделя, среднее 3
      _at(DateTime(2026, 7, 8), mood: 3),
    ];
    final s = StatsService.summary(
        entries, DateTime(2026, 7, 12), DateTime(2026, 7, 18));
    expect(s.average, 4);
    expect(s.daysWithMood, 2);
    expect(s.daysTotal, 7);
    expect(s.delta, 1);
    expect(s.mostCommon, 4);
  });

  test('Корреляция с погодой сортируется по среднему', () {
    final entries = [
      _at(DateTime(2026, 7, 1), mood: 5, weather: 'ясно'),
      _at(DateTime(2026, 7, 2), mood: 4, weather: 'ясно'),
      _at(DateTime(2026, 7, 3), mood: 2, weather: 'дождь'),
    ];
    final c = StatsService.byWeather(entries);
    expect(c.first.key, 'ясно');
    expect(c.first.average, 4.5);
    expect(c.last.key, 'дождь');
  });

  test('Записи без настроения не портят статистику', () {
    final entries = [_at(today), _at(today, mood: 4)];
    expect(StatsService.moodByDay(entries).values.first, 4);
  });
}

void _trackerCorrelationTests() {
  // Связка «настроение × трекеры» — единственная из заявленных, которой не
  // было: корреляции считались только по погоде и действиям.
  group('Настроение и трекеры', () {
    Entry day(int d, int mood) => Entry.create(journalId: 'j').copyWith(
          entryDate: DateTime(2026, 7, d),
          mood: mood,
        );

    test('Дни с бо́льшим сном дают более высокое настроение', () {
      final entries = [day(1, 5), day(2, 5), day(3, 2), day(4, 2)];
      final sleep = {
        20260701: 8.0,
        20260702: 9.0,
        20260703: 4.0,
        20260704: 5.0,
      };
      final out = StatsService.byTracker(entries, {'t-sleep': sleep});
      expect(out, hasLength(2));
      expect(out.first.average, greaterThan(out.last.average));
      expect(out.first.key, 't-sleep${StatsService.trackerMore}');
    });

    test('Одинаковые значения не дают связки', () {
      final entries = [day(1, 5), day(2, 4), day(3, 3), day(4, 2)];
      final flat = {
        20260701: 2.0,
        20260702: 2.0,
        20260703: 2.0,
        20260704: 2.0,
      };
      expect(
        StatsService.byTracker(entries, {'t': flat}),
        isEmpty,
      );
    });

    test('Мало дней — молчим, а не выдумываем вывод', () {
      final entries = [day(1, 5), day(2, 1)];
      expect(
        StatsService.byTracker(
            entries, {'t': {20260701: 1.0, 20260702: 3.0}}),
        isEmpty,
      );
    });
  });
}
