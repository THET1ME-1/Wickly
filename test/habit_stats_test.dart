import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/catalog.dart';
import 'package:wickly/services/habit_stats.dart';

void main() {
  _scheduleTests();
  final now = DateTime(2026, 7, 18);

  /// Карта «день → отмечено» по смещению назад от [now].
  Map<int, double> daysAgo(List<int> offsets) => {
        for (final o in offsets)
          TrackerLog.dayKey(now.subtract(Duration(days: o))): 1,
      };

  group('Серия привычки', () {
    test('Идёт от сегодня назад', () {
      final s = HabitMath.of(daysAgo([0, 1, 2]), now: now);
      expect(s.streak, 3);
    });

    test('Не рвётся, если сегодня ещё не отмечено', () {
      // День не кончился — обнулять счётчик в полдень нечестно.
      final s = HabitMath.of(daysAgo([1, 2, 3]), now: now);
      expect(s.streak, 3);
    });

    test('Рвётся, если пропущен и вчерашний день', () {
      final s = HabitMath.of(daysAgo([2, 3, 4]), now: now);
      expect(s.streak, 0);
      expect(s.best, 3, reason: 'но лучшая серия помнит');
    });

    test('Лучшая серия находится в прошлом', () {
      final s = HabitMath.of(daysAgo([0, 5, 6, 7, 8]), now: now);
      expect(s.streak, 1);
      expect(s.best, 4);
    });
  });

  group('Доля выполнения', () {
    test('Считается за тридцать дней', () {
      final s = HabitMath.of(daysAgo([0, 1, 2, 40, 41]), now: now);
      expect(s.last30, 3, reason: 'сорокадневные в окно не входят');
      expect(s.rate30, closeTo(0.1, 0.001));
      expect(s.total, 5, reason: 'а всего отметок пять');
    });

    test('Пустая привычка ничего не выдумывает', () {
      final s = HabitMath.of(const {}, now: now);
      expect(s.streak, 0);
      expect(s.best, 0);
      expect(s.rate30, 0);
      expect(s.lastDone, isNull);
    });
  });

  group('История для тепловой карты', () {
    test('Длина ровно та, что попросили', () {
      expect(HabitMath.history(daysAgo([0]), days: 70, now: now), hasLength(70));
    });

    test('Свежий день — последний', () {
      final h = HabitMath.history(daysAgo([0]), days: 3, now: now);
      expect(h, [false, false, true]);
    });

    test('Короткая история не ломает сетку', () {
      final h = HabitMath.history(const {}, days: 5, now: now);
      expect(h, everyElement(isFalse));
      expect(h, hasLength(5));
    });
  });
}

void _scheduleTests() {
  final now = DateTime(2026, 7, 18); // суббота
  Map<int, double> onDays(List<int> offsets) => {
        for (final o in offsets)
          TrackerLog.dayKey(now.subtract(Duration(days: o))): 1,
      };

  // Привычка «по будням»: пн–пт.
  bool weekdaysOnly(DateTime d) => d.weekday <= 5;

  group('Расписание привычки', () {
    test('Выходные по расписанию не рвут серию', () {
      // 18 июля 2026 — суббота, её не ждём. Отмечены пять будней подряд:
      // пт, чт, ср, вт, пн.
      final s = HabitMath.of(
        onDays([1, 2, 3, 4, 5]),
        now: now,
        expectedOn: weekdaysOnly,
      );
      expect(s.streak, 5, reason: 'суббота не должна обрывать будни');
    });

    test('Пропущенный ожидаемый день серию рвёт', () {
      // Пятница и среда отмечены, четверг пропущен.
      final s = HabitMath.of(
        onDays([1, 3, 4]),
        now: now,
        expectedOn: weekdaysOnly,
      );
      expect(s.streak, 1);
    });

    test('Доля считается от ожидаемых дней, а не от календарных', () {
      // Все будни за 30 дней отмечены — это сто процентов, а не 71.
      final marked = <int>[];
      for (var i = 0; i < 30; i++) {
        if (weekdaysOnly(now.subtract(Duration(days: i)))) marked.add(i);
      }
      final s = HabitMath.of(
        onDays(marked),
        now: now,
        expectedOn: weekdaysOnly,
      );
      expect(s.rate30, 1.0);
      expect(s.expected30, lessThan(30));
    });

    test('Без расписания считаются все дни', () {
      final s = HabitMath.of(onDays([0, 1]), now: now);
      expect(s.expected30, 30);
    });

    test('Пустое расписание не зацикливает подсчёт', () {
      // Привычка не ожидается никогда — серия ноль, но и зависнуть нельзя.
      final s = HabitMath.of(
        onDays([0, 1, 2]),
        now: now,
        expectedOn: (_) => false,
      );
      expect(s.streak, 0);
      expect(s.expected30, 0);
      expect(s.rate30, 0);
    });
  });
}
