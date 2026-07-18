import 'package:flutter/material.dart';

import '../data/entry_repository.dart';
import '../data/tracker_repository.dart';
import '../models/catalog.dart';
import '../services/stats_service.dart';
import '../services/habit_stats.dart';
import 'habit_screen.dart';
import '../widgets/tracker_editor_sheet.dart';
import 'trackers_screen.dart';

/// Трекеры с настоящими значениями за сегодня и неделю.
class TrackersContainer extends StatefulWidget {
  const TrackersContainer({super.key});

  @override
  State<TrackersContainer> createState() => _TrackersContainerState();
}

class _TrackersContainerState extends State<TrackersContainer> {
  List<TrackerState> _states = const [];
  int? _todayMood;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final trackers = await TrackerRepository.instance.trackers();
    final today = await TrackerRepository.instance.valuesForDay(now);
    final weekStart = now.subtract(const Duration(days: 6));

    final states = <TrackerState>[];
    for (final t in trackers) {
      // Привычке нужна вся история: по ней считаются серии и доля месяца.
      // Счётчику хватает недели — он про «сколько сегодня».
      final habit = t.kind == TrackerKind.habit;
      final from = habit ? now.subtract(const Duration(days: 400)) : weekStart;
      final range = await TrackerRepository.instance.range(t.id, from, now);
      states.add(TrackerState(
        tracker: t,
        today: today[t.id] ?? 0,
        week: [
          for (var i = 6; i >= 0; i--)
            (range[TrackerLog.dayKey(now.subtract(Duration(days: i)))] ?? 0) > 0,
        ],
        habit: habit ? HabitMath.of(range, now: now) : HabitStats.empty,
      ));
    }

    // Настроение дня — среднее по сегодняшним записям.
    final entries = await EntryRepository.instance.forDay(now);
    final mood = StatsService.moodByDay(entries).values.firstOrNull;

    if (!mounted) return;
    setState(() {
      _states = states;
      _todayMood = mood?.round();
    });
  }

  Future<void> _setValue(Tracker tracker, double value) async {
    await TrackerRepository.instance
        .setValue(tracker.id, DateTime.now(), value);
    await _load();
  }

  Future<void> _toggleHabit(Tracker tracker, int dayIndex) async {
    final day = DateTime.now().subtract(Duration(days: 6 - dayIndex));
    final current = await TrackerRepository.instance.range(tracker.id, day, day);
    final done = (current[TrackerLog.dayKey(day)] ?? 0) > 0;
    await TrackerRepository.instance
        .setValue(tracker.id, day, done ? 0 : 1);
    await _load();
  }

  @override
  Widget build(BuildContext context) => TrackersView(
        trackers: _states,
        todayMood: _todayMood,
        onSetValue: _setValue,
        onToggleHabit: _toggleHabit,
        onAdd: () async {
          await showTrackerEditor(context, sort: _states.length);
          await _load();
        },
        onEdit: (t) async {
          await showTrackerEditor(context, tracker: t);
          await _load();
        },
        onOpenHabit: (t) async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => HabitScreen(tracker: t)),
          );
          await _load();
        },
      );
}
