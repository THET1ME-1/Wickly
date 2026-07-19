import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import 'entry_card.dart';

/// Трекер в колонке «Сегодня».
class TodayTracker {
  final String id;
  final String name;
  final double value;
  final double goal;

  /// Привычка отмечается галочкой, число здесь не нужно.
  final bool habit;

  /// Единица измерения уже переведённая («стак.», «ч»).
  final String? unit;

  const TodayTracker({
    required this.id,
    required this.name,
    required this.value,
    required this.goal,
    this.habit = false,
    this.unit,
  });

  double get part => goal <= 0 ? 0 : (value / goal).clamp(0, 1);
}

/// Всё, что колонка показывает про сегодняшний день.
class TodayData {
  final Streak streak;
  final List<bool> lastWeek;

  /// Настроение дня, если сегодня уже отмечали.
  final int? mood;

  /// Эмоции и действия сегодняшнего дня — именами.
  final List<String> marks;

  final List<TodayTracker> trackers;

  /// Запись этого же дня прошлых лет.
  final EntryCardItem? memory;
  final int memoryYears;

  const TodayData({
    this.streak = Streak.empty,
    this.lastWeek = const [],
    this.mood,
    this.marks = const [],
    this.trackers = const [],
    this.memory,
    this.memoryYears = 0,
  });
}

/// Правая колонка широкого окна: сегодняшний день целиком.
///
/// Серия, настроение, трекеры и «в этот день» — то, за чем на телефоне надо
/// уходить на четыре разных экрана. На мониторе для этого есть место.
class DeskToday extends StatelessWidget {
  final TodayData data;
  final ValueChanged<int>? onMood;
  final VoidCallback? onMarks;
  final VoidCallback? onStreak;
  final ValueChanged<TodayTracker>? onTracker;
  final VoidCallback? onMemory;
  final double width;

  const DeskToday({
    super.key,
    required this.data,
    this.onMood,
    this.onMarks,
    this.onStreak,
    this.onTracker,
    this.onMemory,
    this.width = 298,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(left: BorderSide(color: scheme.outlineVariant)),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          _Label(tr('today')),
          _Card(
            onTap: onStreak,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Ring(streak: data.streak),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Dates.daysStreak(data.streak.current),
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trf('streak_best', {'n': '${data.streak.best}'}),
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (data.lastWeek.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final on in data.lastWeek) ...[
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: on
                                  ? scheme.primary
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        if (on != data.lastWeek.last) const SizedBox(width: 5),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),

          _Label(tr('day_mood')),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var m = 1; m <= MoodPalette.levels; m++) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onMood?.call(m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            height: 34,
                            decoration: BoxDecoration(
                              color: MoodPalette.color(context, m)
                                  .withValues(alpha: data.mood == m ? 1 : 0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: data.mood == m
                                  ? Border.all(color: scheme.onSurface, width: 2)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      if (m < MoodPalette.levels) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final mark in data.marks) _Chip(label: mark),
                    _Chip(icon: Icons.add_rounded, onTap: onMarks, accent: true),
                  ],
                ),
              ],
            ),
          ),

          if (data.trackers.isNotEmpty) ...[
            _Label(tr('trackers')),
            _Card(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  for (final t in data.trackers)
                    _TrackerRow(tracker: t, onTap: () => onTracker?.call(t)),
                ],
              ),
            ),
          ],

          if (data.memory != null)
            _Memory(
              item: data.memory!,
              years: data.memoryYears,
              onTap: onMemory,
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.1,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Кольцо серии: заполненная доля — путь к лучшей серии.
class _Ring extends StatelessWidget {
  final Streak streak;
  const _Ring({required this.streak});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final part = streak.best <= 0
        ? 0.0
        : (streak.current / streak.best).clamp(0.05, 1.0);

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: -1.5708,
          endAngle: 4.7124,
          colors: [
            scheme.primary,
            scheme.primary,
            scheme.surfaceContainerHighest,
            scheme.surfaceContainerHighest,
          ],
          stops: [0, part, part, 1],
        ),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${streak.current}',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool accent;

  const _Chip({this.label, this.icon, this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: accent ? scheme.primaryContainer : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: icon == null ? 10 : 8, vertical: 6),
          child: icon != null
              ? Icon(icon, size: 15, color: scheme.onPrimaryContainer)
              : Text(
                  label!,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: accent
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TrackerRow extends StatelessWidget {
  final TodayTracker tracker;
  final VoidCallback? onTap;

  const _TrackerRow({required this.tracker, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = tracker.part >= 1;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: Text(
                tracker.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: tracker.part,
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 42,
              child: tracker.habit
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        done
                            ? Icons.check_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 15,
                        color: done ? scheme.tertiary : scheme.outline,
                      ),
                    )
                  : Text(
                      tracker.unit == null
                          ? '${_n(tracker.value)}/${_n(tracker.goal)}'
                          : '${_n(tracker.value)} ${tracker.unit}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 11.5,
                        color: scheme.outline,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
}

/// «В этот день» — единственное цветное пятно в колонке.
class _Memory extends StatelessWidget {
  final EntryCardItem item;
  final int years;
  final VoidCallback? onTap;

  const _Memory({required this.item, required this.years, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.secondaryContainer, scheme.primaryContainer],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 14, color: scheme.onSecondaryContainer),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${tr('on_this_day')} · ${Dates.yearsAgo(years)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '«${EntryCard.titleOf(item.entry)}»',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14,
                    height: 1.35,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
