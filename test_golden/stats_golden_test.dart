import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/catalog.dart';
import 'package:wickly/screens/mood_stats_screen.dart';
import 'package:wickly/screens/trackers_screen.dart';
import 'package:wickly/services/stats_service.dart';

import 'harness.dart';
import 'samples.dart';

void main() {
  testWidgets('Статистика настроения', (tester) async {
    final month = Samples.month();
    final summary = StatsService.summary(
        month, DateTime(2026, 7, 1), DateTime(2026, 7, 17));
    final byDay = StatsService.moodByDay(month);
    await Harness.shoot(
      tester,
      'stats',
      () => MoodStatsView(
        dataFor: (_) => MoodStatsData(
          summary: summary,
          streak: Samples.streak,
          trend: [
            for (var d = 1; d <= 31; d++) byDay[20260700 + d],
          ],
          byWeather: StatsService.byWeather(month),
          startLabel: '1 июл',
          middleLabel: '17 июл',
          endLabel: '31',
        ),
      ),
    );
  });

  testWidgets('Трекеры и привычки', (tester) async {
    const water = Tracker(
        id: 'trk_water',
        name: '',
        kind: TrackerKind.number,
        unit: 'unit_glasses',
        goal: 8,
        icon: 'water',
        builtin: 'trk_water');
    const sleep = Tracker(
        id: 'trk_sleep',
        name: '',
        kind: TrackerKind.duration,
        unit: 'unit_hours',
        goal: 8,
        icon: 'sleep',
        builtin: 'trk_sleep');
    const steps = Tracker(
        id: 'trk_steps',
        name: '',
        kind: TrackerKind.number,
        unit: 'unit_steps',
        goal: 10000,
        icon: 'steps',
        builtin: 'trk_steps');
    const read = Tracker(
        id: 'trk_read',
        name: '',
        kind: TrackerKind.habit,
        goal: 1,
        icon: 'book',
        builtin: 'trk_read');
    const workout = Tracker(
        id: 'trk_workout',
        name: '',
        kind: TrackerKind.habit,
        goal: 1,
        icon: 'pulse',
        builtin: 'trk_workout');
    const social = Tracker(
        id: 'trk_no_social',
        name: '',
        kind: TrackerKind.habit,
        goal: 1,
        icon: 'no_phone',
        builtin: 'trk_no_social');

    await Harness.shoot(
      tester,
      'trackers',
      () => const TrackersView(
        todayMood: 4,
        trackers: [
          TrackerState(tracker: water, today: 6),
          TrackerState(tracker: sleep, today: 7.5),
          TrackerState(tracker: steps, today: 8200),
          TrackerState(
              tracker: read,
              today: 1,
              week: [true, true, true, false, true, true, false]),
          TrackerState(
              tracker: workout,
              today: 0,
              week: [true, false, true, true, true, true, false]),
          TrackerState(
              tracker: social,
              today: 1,
              week: [true, true, false, true, true, true, true]),
        ],
      ),
    );
  });
}
