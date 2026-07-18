import 'package:flutter/material.dart';

import '../theme/feedback.dart';
import '../l10n/strings.dart';
import '../models/catalog.dart';
import '../services/habit_stats.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/catalog_names.dart';
import '../widgets/count_up_number.dart';
import '../widgets/mood_chart.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// Трекер вместе с его значением за сегодня и картиной недели.
class TrackerState {
  final Tracker tracker;
  final double today;

  /// Семь дней, свежий — последний. Для привычки: сделал или нет.
  final List<bool> week;

  /// Серия и доля выполнения — только у привычек.
  final HabitStats habit;

  const TrackerState({
    required this.tracker,
    required this.today,
    this.week = const [],
    this.habit = HabitStats.empty,
  });

  double get progress {
    final goal = tracker.goal ?? 0;
    if (goal <= 0) return 0;
    return (today / goal).clamp(0, 1);
  }
}

/// Трекеры и привычки: вода, сон, шаги и свои привычки.
///
/// Числовые трекеры — плитками с кольцом прогресса, привычки — строками с
/// недельной сеткой: у них разный вопрос. У числа спрашивают «сколько сегодня»,
/// у привычки — «часто ли вообще».
class TrackersView extends StatelessWidget {
  final List<TrackerState> trackers;

  /// Настроение дня показывается рядом с трекерами — оно тоже дневной замер.
  final int? todayMood;

  final void Function(Tracker tracker, double value)? onSetValue;
  final void Function(Tracker tracker, int dayIndex)? onToggleHabit;
  final VoidCallback? onAdd;
  final void Function(Tracker tracker)? onEdit;

  /// Открыть привычку целиком: история, серии, статистика.
  final void Function(Tracker tracker)? onOpenHabit;

  const TrackersView({
    super.key,
    required this.trackers,
    this.todayMood,
    this.onSetValue,
    this.onToggleHabit,
    this.onAdd,
    this.onEdit,
    this.onOpenHabit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final counters =
        trackers.where((t) => t.tracker.kind != TrackerKind.habit).toList();
    final habits =
        trackers.where((t) => t.tracker.kind == TrackerKind.habit).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('trackers')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: onAdd,
            tooltip: tr('new_tracker'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 4,
            WicklyDesign.screenPad, 28),
        children: [
          Text(
            tr('today').toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: WicklyDesign.gapCards,
            mainAxisSpacing: WicklyDesign.gapCards,
            childAspectRatio: 1.55,
            children: [
              for (var i = 0; i < counters.length; i++)
                Reveal(
                  delay: Duration(milliseconds: 40 * (i < 4 ? i : 4)),
                  child: _CounterTile(
                    state: counters[i],
                    onSetValue: onSetValue,
                    onEdit: onEdit,
                  ),
                ),
              if (todayMood != null)
                Reveal(
                  delay: Duration(milliseconds: 40 * counters.length),
                  child: _MoodTile(mood: todayMood!),
                ),
            ],
          ),
          if (habits.isNotEmpty) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(WicklyDesign.gapInside),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('habits'),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final (i, h) in habits.indexed)
                    Reveal(
                      delay: WicklyDesign.revealDelay(i),
                      child: _HabitRow(
                        state: h,
                        onToggle: onToggleHabit,
                        onOpen: onOpenHabit,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Строка привычки: серия, неделя и переход к её истории.
///
/// Раньше здесь была одна строка с семью кружками — по ней не видно ни серии,
/// ни того, как шёл месяц. Теперь строка отвечает на «часто ли вообще» и
/// открывает привычку целиком.
class _HabitRow extends StatelessWidget {
  final TrackerState state;
  final void Function(Tracker tracker, int dayIndex)? onToggle;
  final void Function(Tracker tracker)? onOpen;

  const _HabitRow({required this.state, this.onToggle, this.onOpen});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = state.tracker;
    final tint = t.color == null ? scheme.primary : Color(t.color!);
    final streak = state.habit.streak;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onOpen == null
            ? null
            : () {
                Haptics.tap();
                onOpen!(t);
              },
        behavior: HitTestBehavior.opaque,
        child: PressableScale(
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(AppIcons.resolve(t.icon), size: 18, color: tint),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      CatalogNames.of(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      streak > 0
                          ? trf('habit_streak_days', {'n': streak})
                          : trf('habit_rate_short', {
                              'n': state.habit.last30,
                              'of': state.habit.expected30,
                            }),
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 11.5,
                        color: streak > 0 ? tint : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HabitWeek(
                days: state.week.length == 7
                    ? state.week
                    : List.filled(7, false),
                color: t.color == null ? null : Color(t.color!),
                onToggle:
                    onToggle == null ? null : (i) => onToggle!(t, i),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Плитка числового трекера: значение, цель и кольцо прогресса.
class _CounterTile extends StatelessWidget {
  final TrackerState state;
  final void Function(Tracker tracker, double value)? onSetValue;
  final void Function(Tracker tracker)? onEdit;

  const _CounterTile({required this.state, this.onSetValue, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = state.tracker;
    final tint = t.color == null ? scheme.primary : Color(t.color!);
    final unit = t.unit == null
        ? ''
        : (hasTr(t.unit!) ? tr(t.unit!) : t.unit!);

    return PressableScale(
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Тап добавляет шаг, долгий тап открывает правку: наливать воду по
          // стакану нужно каждый день, а менять цель — раз в полгода.
          onTap: onSetValue == null
              ? null
              : () {
                  final next = state.today + _step(t);
                  // Цель взята прямо сейчас — это стоит почувствовать.
                  // Цели может не быть вовсе: тогда просто шаг.
                  final goal = t.goal;
                  final reached = goal != null &&
                      goal > 0 &&
                      state.today < goal &&
                      next >= goal;
                  reached ? Haptics.celebrate() : Haptics.tap();
                  onSetValue!(t, next);
                },
          onLongPress: onEdit == null ? null : () => onEdit!(t),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(AppIcons.resolve(t.icon), size: 18, color: tint),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Число с целью не должно ни налезать на кольцо, ни
                          // терять символы: если места мало — ужимаем целиком.
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              CountUpNumber(
                                  value: state.today,
                                  fractionDigits:
                                      t.kind == TrackerKind.duration ? 1 : 0,
                                  compact: true,
                                  thousandSuffix: tr('thousand_short'),
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              if (t.goal != null)
                                Text(
                                    '/${_short(t.goal!)}',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: AppTheme.displayFont,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                            ],
                          ),
                          ),
                          Text(
                            unit.isEmpty ? CatalogNames.of(t) : unit,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ProgressRing(
                      progress: state.progress,
                      color: tint,
                      size: 40,
                      child: Text(
                        '${(state.progress * 100).round()}',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Шаг по тапу: стакан воды, полчаса сна, тысяча шагов.
  static double _step(Tracker t) => switch (t.kind) {
        TrackerKind.duration => 0.5,
        TrackerKind.habit => 1,
        TrackerKind.number => (t.goal ?? 0) >= 1000 ? 1000 : 1,
      };

  /// «10000» в плитке не помещается — показываем «10к».
  static String _short(double v) {
    if (v >= 1000) {
      final k = v / 1000;
      return '${k % 1 == 0 ? k.toInt() : k.toStringAsFixed(1)}'
          '${tr('thousand_short')}';
    }
    return v % 1 == 0 ? '${v.toInt()}' : v.toStringAsFixed(1);
  }
}

/// Настроение дня рядом с трекерами.
class _MoodTile extends StatelessWidget {
  final int mood;
  const _MoodTile({required this.mood});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mood_rounded, size: 18, color: scheme.primary),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _short(context, mood),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.5,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      tr('set_mood').toLowerCase(),
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              MoodDot(mood: mood, size: 26),
            ],
          ),
        ],
      ),
    );
  }

  /// Длинные подписи вроде «Так себе» в плитку не влезают.
  static String _short(BuildContext context, int mood) {
    final label = MoodPaletteX.label(mood);
    return label.length <= 8 ? label : '${label.substring(0, 7)}.';
  }
}
