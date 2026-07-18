import '../models/catalog.dart';

/// Что известно про привычку за всё время наблюдения.
class HabitStats {
  /// Сколько дней подряд идёт сейчас.
  final int streak;

  /// Лучшая серия за всё время.
  final int best;

  /// Сколько раз отмечена за последние 30 дней.
  final int last30;

  /// Сколько раз за те же 30 дней её вообще ожидали по расписанию.
  final int expected30;

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
    this.expected30 = 30,
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
  ///
  /// [expectedOn] задаёт расписание: дни, в которые привычка не ожидается,
  /// серию не рвут и в долю выполнения не входят. Без этого «спорт трижды в
  /// неделю» выглядел бы вечным провалом, а честнее считать только те дни,
  /// когда человек сам обещал.
  static HabitStats of(
    Map<int, double> byDay, {
    DateTime? now,
    bool Function(DateTime day)? expectedOn,
  }) {
    if (byDay.isEmpty) return HabitStats.empty;

    bool expected(DateTime d) => expectedOn?.call(d) ?? true;

    final today = _midnight(now ?? DateTime.now());
    final doneToday = done(byDay, today);

    // Сегодняшний день не засчитываем в разрыв: он ещё идёт.
    var cursor = doneToday ? today : today.subtract(const Duration(days: 1));
    var streak = 0;
    // Столько дней назад заглядываем максимум: у пустого расписания цикл
    // иначе ушёл бы в бесконечность на неотмеченных днях.
    for (var guard = 0; guard < 400; guard++) {
      if (!expected(cursor)) {
        // Выходной по расписанию: серию не рвёт и в счёт не идёт.
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (!done(byDay, cursor)) break;
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

    // Доля считается от ожидаемых дней, а не от календарных: у привычки на
    // три дня в неделю потолок иначе был бы 43 %, и полоса всегда врала бы.
    var last30 = 0, expected30 = 0;
    for (var i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      if (!expected(day)) continue;
      expected30++;
      if (done(byDay, day)) last30++;
    }

    return HabitStats(
      streak: streak,
      best: best < streak ? streak : best,
      last30: last30,
      expected30: expected30,
      rate30: expected30 == 0 ? 0 : last30 / expected30,
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
