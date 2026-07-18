import '../models/catalog.dart';

/// Что известно про привычку за всё время наблюдения.
class HabitStats {
  /// Сколько дней подряд идёт сейчас.
  final int streak;

  /// Лучшая серия за всё время.
  final int best;

  /// Сколько раз отмечена за последние 30 дней.
  final int last30;

  /// Доля выполнения за последние 30 дней, 0..1.
  final double rate30;

  /// Всего отметок за всё время.
  final int total;

  /// Когда отмечена в последний раз.
  final DateTime? lastDone;

  const HabitStats({
    this.streak = 0,
    this.best = 0,
    this.last30 = 0,
    this.rate30 = 0,
    this.total = 0,
    this.lastDone,
  });

  static const empty = HabitStats();
}

/// Счёт по привычкам: серии, доля выполнения, история по дням.
///
/// Чистые функции над картой «день → значение», как её отдаёт репозиторий.
/// Живут отдельно от экрана и считаются без базы — поэтому проверяются
/// тестами и не тянут Flutter.
class HabitMath {
  const HabitMath._();

  /// Отмечен ли день.
  static bool done(Map<int, double> byDay, DateTime day) =>
      (byDay[TrackerLog.dayKey(day)] ?? 0) > 0;

  /// Считает всё сразу — один проход вместо четырёх.
  ///
  /// Серия не рвётся, если сегодня ещё не отмечено: день не кончился, и
  /// обнулять счётчик в полдень было бы нечестно. Она держится на вчерашнем
  /// дне до полуночи — так же, как серия записей в дневнике.
  static HabitStats of(Map<int, double> byDay, {DateTime? now}) {
    if (byDay.isEmpty) return HabitStats.empty;

    final today = _midnight(now ?? DateTime.now());
    final doneToday = done(byDay, today);

    var cursor = doneToday ? today : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (done(byDay, cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Лучшая серия: идём по отсортированным дням и считаем разрывы.
    final days = byDay.entries
        .where((e) => e.value > 0)
        .map((e) => TrackerLog.dayFromKey(e.key))
        .toList()
      ..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final day in days) {
      run = (prev != null && day.difference(prev).inDays == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = day;
    }

    var last30 = 0;
    for (var i = 0; i < 30; i++) {
      if (done(byDay, today.subtract(Duration(days: i)))) last30++;
    }

    return HabitStats(
      streak: streak,
      best: best < streak ? streak : best,
      last30: last30,
      rate30: last30 / 30,
      total: days.length,
      lastDone: days.isEmpty ? null : days.last,
    );
  }

  /// История по дням для тепловой карты: свежий день — последний.
  ///
  /// Возвращает ровно [days] значений, чтобы сетка не прыгала по ширине,
  /// когда у привычки короткая история.
  static List<bool> history(
    Map<int, double> byDay, {
    required int days,
    DateTime? now,
  }) {
    final today = _midnight(now ?? DateTime.now());
    return [
      for (var i = days - 1; i >= 0; i--)
        done(byDay, today.subtract(Duration(days: i))),
    ];
  }

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
}
