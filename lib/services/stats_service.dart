import '../models/catalog.dart';
import '../models/entry.dart';

/// Серия дней подряд, в которые человек что-то записал.
class Streak {
  /// Сколько дней подряд идёт сейчас.
  final int current;

  /// Лучшая серия за всё время.
  final int best;

  /// Записал ли уже сегодня.
  final bool writtenToday;

  const Streak({
    required this.current,
    required this.best,
    required this.writtenToday,
  });

  static const empty = Streak(current: 0, best: 0, writtenToday: false);
}

/// Сводка настроения за период.
class MoodSummary {
  /// Среднее по дням с отмеченным настроением.
  final double average;

  /// Сколько дней из периода имеют настроение.
  final int daysWithMood;
  final int daysTotal;

  /// Самое частое настроение.
  final int? mostCommon;

  /// Насколько среднее выросло/упало против прошлого такого же периода.
  final double delta;

  const MoodSummary({
    required this.average,
    required this.daysWithMood,
    required this.daysTotal,
    required this.mostCommon,
    required this.delta,
  });

  static const empty = MoodSummary(
      average: 0, daysWithMood: 0, daysTotal: 0, mostCommon: null, delta: 0);
}

/// Одна строка корреляции: «Ясно — 4,4».
class Correlation {
  final String key;
  final double average;
  final int count;

  const Correlation({
    required this.key,
    required this.average,
    required this.count,
  });
}

/// Счёт по записям: серии, настроение, корреляции.
///
/// Чистые функции над списком записей — считаются в памяти и проверяются
/// тестами без базы. Дневник — не аналитическая система: даже за десять лет тут
/// тысячи записей, поэтому проход по списку дешевле, чем SQL по шифртексту.
class StatsService {
  const StatsService._();

  /// Суффиксы ключей связки с трекером — по ним экран подставляет подпись.
  static const trackerMore = '#more';
  static const trackerLess = '#less';

  static int _dayKey(DateTime d) => TrackerLog.dayKey(d);

  /// Дни, в которые есть хотя бы одна запись.
  static Set<int> writtenDays(List<Entry> entries) =>
      {for (final e in entries) _dayKey(e.entryDate)};

  /// Серия: считаем назад от сегодня. Если сегодня ещё не писал, серию не
  /// обрываем — она держится на вчерашнем дне до конца суток.
  static Streak streak(List<Entry> entries, {DateTime? now}) {
    if (entries.isEmpty) return Streak.empty;
    final days = writtenDays(entries);
    final today = _midnight(now ?? DateTime.now());
    final writtenToday = days.contains(_dayKey(today));

    var cursor = writtenToday ? today : today.subtract(const Duration(days: 1));
    var current = 0;
    while (days.contains(_dayKey(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Лучшая серия: идём по отсортированным дням и считаем разрывы.
    final sorted = days.toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final key in sorted) {
      final day = TrackerLog.dayFromKey(key);
      if (prev != null && day.difference(prev).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > best) best = run;
      prev = day;
    }

    return Streak(
      current: current,
      best: best < current ? current : best,
      writtenToday: writtenToday,
    );
  }

  /// Настроение по дням: если за день несколько записей — берём среднее.
  static Map<int, double> moodByDay(List<Entry> entries) {
    final sums = <int, double>{};
    final counts = <int, int>{};
    for (final e in entries) {
      final m = e.mood;
      if (m == null) continue;
      final key = _dayKey(e.entryDate);
      sums[key] = (sums[key] ?? 0) + m;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return {
      for (final key in sums.keys) key: sums[key]! / counts[key]!,
    };
  }

  /// Сводка за отрезок [from]..[to] включительно.
  static MoodSummary summary(
    List<Entry> entries,
    DateTime from,
    DateTime to,
  ) {
    final byDay = moodByDay(entries);
    final fromKey = _dayKey(from);
    final toKey = _dayKey(to);
    final inRange = {
      for (final e in byDay.entries)
        if (e.key >= fromKey && e.key <= toKey) e.key: e.value,
    };
    if (inRange.isEmpty) {
      return MoodSummary(
        average: 0,
        daysWithMood: 0,
        daysTotal: to.difference(from).inDays + 1,
        mostCommon: null,
        delta: 0,
      );
    }

    final average =
        inRange.values.reduce((a, b) => a + b) / inRange.length;

    // Прошлый отрезок такой же длины — для стрелки «+0,4».
    final span = to.difference(from).inDays + 1;
    final prevTo = from.subtract(const Duration(days: 1));
    final prevFrom = prevTo.subtract(Duration(days: span - 1));
    final prev = {
      for (final e in byDay.entries)
        if (e.key >= _dayKey(prevFrom) && e.key <= _dayKey(prevTo))
          e.key: e.value,
    };
    final prevAvg = prev.isEmpty
        ? average
        : prev.values.reduce((a, b) => a + b) / prev.length;

    // Самое частое настроение — по округлённым дневным значениям.
    final histogram = <int, int>{};
    for (final v in inRange.values) {
      final rounded = v.round().clamp(1, 5);
      histogram[rounded] = (histogram[rounded] ?? 0) + 1;
    }
    int? mostCommon;
    var bestCount = 0;
    histogram.forEach((mood, count) {
      if (count > bestCount) {
        bestCount = count;
        mostCommon = mood;
      }
    });

    return MoodSummary(
      average: average,
      daysWithMood: inRange.length,
      daysTotal: span,
      mostCommon: mostCommon,
      delta: average - prevAvg,
    );
  }

  /// Настроение в разрезе погоды: «Ясно 4,4 · Дождь 3,1».
  static List<Correlation> byWeather(List<Entry> entries) =>
      _correlate(entries, (e) => e.weather == null ? const [] : [e.weather!]);

  /// Настроение в разрезе действий — на вход идёт карта «запись → действия».
  static List<Correlation> byActivity(
    List<Entry> entries,
    Map<String, List<String>> activitiesByEntry,
  ) =>
      _correlate(entries, (e) => activitiesByEntry[e.id] ?? const []);

  /// Настроение в разрезе трекеров: «Сон побольше 4,3 · Сон поменьше 3,2».
  ///
  /// Самая ценная связка из заявленных — и единственная, которой не было:
  /// корреляции считались только по погоде и действиям, а логи трекеров в
  /// статистику не заглядывали вовсе.
  ///
  /// День делим по медиане значений самого трекера, а не по «выполнено»:
  /// у воды и сна нет отметки «сделано», у них есть «сколько». Медиана
  /// устойчивее среднего к одному дню, когда человек проспал полсуток.
  /// Ключи возвращаются служебными («id#more»/«id#less»): подставлять имена и
  /// переводить — дело экрана. Сервис обязан оставаться чистым Dart без
  /// Flutter, иначе он перестаёт гоняться в `tool/db_smoke.dart`.
  static List<Correlation> byTracker(
    List<Entry> entries,
    Map<String, Map<int, double>> valuesByTracker,
  ) {
    final out = <Correlation>[];

    for (final entry in valuesByTracker.entries) {
      final byDay = entry.value;
      if (byDay.length < 4) continue;

      final sorted = byDay.values.toList()..sort();
      final median = sorted[sorted.length ~/ 2];
      // Все дни одинаковые — делить нечего, связка ничего не покажет.
      if (sorted.first == sorted.last) continue;

      var highSum = 0.0, lowSum = 0.0;
      var highCount = 0, lowCount = 0;
      for (final e in entries) {
        final mood = e.mood;
        if (mood == null) continue;
        final value = byDay[TrackerLog.dayKey(e.entryDate)];
        if (value == null) continue;
        if (value >= median) {
          highSum += mood;
          highCount++;
        } else {
          lowSum += mood;
          lowCount++;
        }
      }
      // Одна сторона пустая — сравнивать не с чем.
      if (highCount < 2 || lowCount < 2) continue;

      out.add(Correlation(
        key: '${entry.key}$trackerMore',
        average: highSum / highCount,
        count: highCount,
      ));
      out.add(Correlation(
        key: '${entry.key}$trackerLess',
        average: lowSum / lowCount,
        count: lowCount,
      ));
    }

    out.sort((a, b) => b.average.compareTo(a.average));
    return out;
  }

  static List<Correlation> _correlate(
    List<Entry> entries,
    List<String> Function(Entry) keysOf,
  ) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final e in entries) {
      final m = e.mood;
      if (m == null) continue;
      for (final key in keysOf(e)) {
        sums[key] = (sums[key] ?? 0) + m;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final out = [
      for (final key in sums.keys)
        Correlation(
          key: key,
          average: sums[key]! / counts[key]!,
          count: counts[key]!,
        ),
    ];
    out.sort((a, b) => b.average.compareTo(a.average));
    return out;
  }

  /// Сколько слов человек написал за всё время.
  static int totalWords(List<Entry> entries) =>
      entries.fold(0, (sum, e) => sum + e.wordCount);

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
}
