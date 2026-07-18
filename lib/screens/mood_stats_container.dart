import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../l10n/strings.dart';
import '../data/tracker_repository.dart';
import '../data/entry_repository.dart';
import '../models/entry.dart';
import '../services/stats_service.dart';
import '../utils/catalog_names.dart';
import '../utils/dates.dart';
import 'mood_stats_screen.dart';

/// Статистика настроения на настоящих записях.
class MoodStatsContainer extends StatefulWidget {
  const MoodStatsContainer({super.key});

  @override
  State<MoodStatsContainer> createState() => _MoodStatsContainerState();
}

class _MoodStatsContainerState extends State<MoodStatsContainer> {
  List<Entry> _entries = const [];

  /// Имена действий по id — иначе в корреляциях были бы голые идентификаторы.
  Map<String, String> _activityNames = const {};
  Map<String, List<String>> _activityLinks = const {};
  Map<String, String> _trackerNames = const {};
  Map<String, Map<int, double>> _trackerValues = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await EntryRepository.instance.allEntries();
    final activities = await CatalogRepository.instance.activities();
    final links = await CatalogRepository.instance
        .allLinks('entry_activities', 'activity_id');

    // Логи трекеров за последний год — из них считается связка «настроение
    // и сон/вода/шаги». Раньше трекеры в статистику не заглядывали вовсе.
    final trackers = await TrackerRepository.instance.trackers();
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 365));
    final values = <String, Map<int, double>>{};
    for (final t in trackers) {
      values[t.id] = await TrackerRepository.instance.range(t.id, from, now);
    }

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _activityNames = {
        for (final a in activities) a.id: CatalogNames.of(a),
      };
      _activityLinks = links;
      _trackerNames = {for (final t in trackers) t.id: CatalogNames.of(t)};
      _trackerValues = values;
    });
  }

  MoodStatsData _dataFor(StatsRange range) {
    final now = DateTime.now();
    final (from, days) = switch (range) {
      StatsRange.week => (now.subtract(const Duration(days: 6)), 7),
      StatsRange.month => (DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0).day),
      StatsRange.year => (DateTime(now.year, 1, 1), 365),
    };

    final byDay = StatsService.moodByDay(_entries);
    final inRange = _entries
        .where((e) => !e.entryDate.isBefore(DateTime(from.year, from.month, from.day)))
        .toList();

    // Год рисуем по месяцам: 365 точек на экран телефона не помещаются.
    final trend = range == StatsRange.year
        ? _byMonth(byDay, now.year)
        : [
            for (var i = 0; i < days; i++)
              byDay[TrackerDayKey.of(from.add(Duration(days: i)))],
          ];

    final activityCorrelations = StatsService
        .byActivity(inRange, _activityLinks)
        .map((c) => Correlation(
              key: _activityNames[c.key] ?? c.key,
              average: c.average,
              count: c.count,
            ))
        .toList();

    return MoodStatsData(
      summary: StatsService.summary(_entries, from, now),
      streak: StatsService.streak(_entries, now: now),
      trend: trend,
      byWeather: StatsService.byWeather(inRange),
      byActivity: [
        ...activityCorrelations,
        ...StatsService.byTracker(inRange, _trackerValues).map(_trackerLabel),
      ],
      startLabel: range == StatsRange.year
          ? '${now.year}'
          : Dates.dayMonth(from),
      middleLabel: range == StatsRange.year ? '' : Dates.dayMonth(now),
      endLabel: range == StatsRange.year ? '' : '',
    );
  }

  /// Служебный ключ связки с трекером превращается в человеческую подпись.
  /// Перевод живёт здесь, а не в сервисе: сервис — чистый Dart.
  Correlation _trackerLabel(Correlation c) {
    final more = c.key.endsWith(StatsService.trackerMore);
    final id = c.key.substring(
        0, c.key.length - (more ? StatsService.trackerMore : StatsService.trackerLess).length);
    final name = _trackerNames[id] ?? id;
    return Correlation(
      key: trf(more ? 'corr_tracker_more' : 'corr_tracker_less', {'name': name}),
      average: c.average,
      count: c.count,
    );
  }

  /// Среднее по месяцам для годового графика.
  static List<double?> _byMonth(Map<int, double> byDay, int year) {
    final sums = List<double>.filled(12, 0);
    final counts = List<int>.filled(12, 0);
    byDay.forEach((key, value) {
      if (key ~/ 10000 != year) return;
      final month = (key ~/ 100) % 100;
      sums[month - 1] += value;
      counts[month - 1]++;
    });
    return [
      for (var i = 0; i < 12; i++)
        counts[i] == 0 ? null : sums[i] / counts[i],
    ];
  }

  @override
  Widget build(BuildContext context) => MoodStatsView(dataFor: _dataFor);
}

/// Ключ дня в том же виде, что в трекерах: yyyymmdd.
class TrackerDayKey {
  const TrackerDayKey._();
  static int of(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}
