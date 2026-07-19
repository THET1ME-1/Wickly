import 'package:flutter/material.dart';

import '../theme/feedback.dart';
import '../l10n/strings.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/count_up_number.dart';
import '../widgets/mood_chart.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// Что нужно календарю: настроение по дням, сводка месяца и серия.
class CalendarData {
  /// Настроение дня: ключ `yyyymmdd` → среднее за день.
  final Map<int, double> moodByDay;

  /// В какие дни есть записи (день может быть без настроения).
  final Set<int> writtenDays;

  final MoodSummary summary;
  final Streak streak;

  /// Показываемый месяц.
  final DateTime month;
  final DateTime now;

  /// Записей и слов за показываемый месяц — сводка считала только дни.
  final int entriesThisMonth;
  final int wordsThisMonth;

  /// Сколько записей в каждом дне: `yyyymmdd` → счётчик. Нужен хронике —
  /// в клетке месяца стоит число, а не только цвет.
  final Map<int, int> countByDay;

  const CalendarData({
    required this.moodByDay,
    required this.writtenDays,
    required this.summary,
    required this.streak,
    required this.month,
    required this.now,
    this.entriesThisMonth = 0,
    this.wordsThisMonth = 0,
    this.countByDay = const {},
  });

  /// Настроение по дням месяца для графика: пропуск — день без отметки.
  List<double?> get moodTrend {
    final days = DateTime(month.year, month.month + 1, 0).day;
    return [
      for (var d = 1; d <= days; d++)
        moodByDay[month.year * 10000 + month.month * 100 + d],
    ];
  }
}

/// Календарь настроения: каждый день окрашен тем, как он прошёл.
///
/// Месяц целиком на одном экране — так видно полосы: неделя провалов, ровный
/// период, пропуски. Ниже — сводка, чтобы не считать глазами.
class CalendarView extends StatelessWidget {
  final CalendarData data;
  final ValueChanged<DateTime>? onOpenDay;
  final ValueChanged<DateTime>? onChangeMonth;
  final VoidCallback? onWrite;

  const CalendarView({
    super.key,
    required this.data,
    this.onOpenDay,
    this.onChangeMonth,
    this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: onWrite,
        child: const Icon(Icons.edit_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 4,
              WicklyDesign.screenPad, 96),
          children: [
            _MonthHeader(
              month: data.month,
              onPrev: () {
                Haptics.tap();
                onChangeMonth
                    ?.call(DateTime(data.month.year, data.month.month - 1));
              },
              onNext: () {
                Haptics.tap();
                onChangeMonth
                    ?.call(DateTime(data.month.year, data.month.month + 1));
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final h in Dates.weekdayHeaders())
                  Expanded(
                    child: Center(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Месяц не появляется заново, а сменяется: сетка уезжает в ту
            // сторону, куда листаешь. Ключ по месяцу — иначе переключатель
            // не поймёт, что содержимое другое.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: AppTheme.emphasizedDecelerate,
              switchOutCurve: AppTheme.emphasized,
              transitionBuilder: (child, animation) {
                final forward =
                    child.key == ValueKey(data.month.millisecondsSinceEpoch);
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(forward ? 0.06 : -0.06, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _MonthGrid(
                key: ValueKey(data.month.millisecondsSinceEpoch),
                data: data,
                onOpenDay: onOpenDay,
              ),
            ),
            const SizedBox(height: 18),
            Reveal(child: _SummaryCard(data: data)),
          ],
        ),
      ),
    );
  }
}

/// «‹ Июль 2026 ›» — переключение месяцев.
class _MonthHeader extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: tr('back'),
        ),
        Expanded(
          child: Center(
            child: Text(
              Dates.monthYear(month),
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Сетка месяца: день с настроением — закрашенный кружок, день с записью без
/// настроения — обводка, сегодня — кольцо акцента.
class _MonthGrid extends StatelessWidget {
  final CalendarData data;
  final ValueChanged<DateTime>? onOpenDay;

  const _MonthGrid({super.key, required this.data, this.onOpenDay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(data.month.year, data.month.month, 1);
    final daysInMonth =
        DateTime(data.month.year, data.month.month + 1, 0).day;
    // Понедельник — первый столбец: weekday у DateTime 1=Пн.
    final leading = first.weekday - 1;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        for (var r = 0; r < rows; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(builder: (context) {
                      final index = r * 7 + c;
                      final dayNum = index - leading + 1;
                      if (dayNum < 1 || dayNum > daysInMonth) {
                        return const SizedBox(height: 44);
                      }
                      final date = DateTime(
                          data.month.year, data.month.month, dayNum);
                      final key = date.year * 10000 +
                          date.month * 100 +
                          date.day;
                      final mood = data.moodByDay[key];
                      final written = data.writtenDays.contains(key);
                      final isToday = date.year == data.now.year &&
                          date.month == data.now.month &&
                          date.day == data.now.day;
                      final future = date.isAfter(DateTime(
                          data.now.year, data.now.month, data.now.day));

                      return _DayCell(
                        day: dayNum,
                        mood: mood?.round(),
                        written: written,
                        isToday: isToday,
                        dimmed: future,
                        onTap: () => onOpenDay?.call(date),
                      );
                    }),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 2),
        // Легенда шкалы — без неё цвета читаются как украшение.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final m in MoodPaletteX.levels) ...[
              MoodDot(mood: m, size: 8),
              if (m != MoodPaletteX.levels.last) const SizedBox(width: 6),
            ],
            const SizedBox(width: 8),
            Text(
              tr('mood_of_month').toLowerCase(),
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Один день месяца.
class _DayCell extends StatelessWidget {
  final int day;
  final int? mood;
  final bool written;
  final bool isToday;
  final bool dimmed;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    this.mood,
    required this.written,
    required this.isToday,
    required this.dimmed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = mood != null;
    final color = MoodPalette.color(context, mood);

    return SizedBox(
      height: 44,
      child: Center(
        child: PressableScale(
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: dimmed ? null : onTap,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? color : Colors.transparent,
                  border: isToday
                      ? Border.all(color: scheme.onSurface, width: 2)
                      : (written && !filled
                          ? Border.all(color: scheme.outline, width: 1.5)
                          : null),
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13.5,
                    fontWeight:
                        filled || isToday ? FontWeight.w700 : FontWeight.w500,
                    color: filled
                        ? MoodPalette.on(context, mood)
                        : (dimmed
                            ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                            : scheme.onSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Сводка месяца: среднее, серия и самое частое настроение.
class _SummaryCard extends StatelessWidget {
  final CalendarData data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = data.summary;

    return Container(
      padding: const EdgeInsets.all(WicklyDesign.gapInside),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tr('mood_of_month'),
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                trf('days_of_count',
                    {'a': s.daysWithMood, 'b': s.daysTotal}),
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // График месяца: по нему видно полосы — неделя провалов, ровный
          // период, пропуски. Раньше на календаре были только три числа.
          if (data.moodByDay.isNotEmpty)
            MoodChart(
              values: data.moodTrend,
              height: 84,
              startLabel: '1',
              middleLabel: '${DateTime(data.month.year, data.month.month + 1, 0).day ~/ 2}',
              endLabel: '${DateTime(data.month.year, data.month.month + 1, 0).day}',
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: CountUpNumber(
                    value: s.average,
                    fractionDigits: 1,
                    style: _valueStyle(context),
                  ),
                  label: tr('average'),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: CountUpNumber(
                    value: data.streak.current.toDouble(),
                    style: _valueStyle(context),
                  ),
                  label: tr('streak_short'),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: MoodDot(mood: s.mostCommon, size: 22),
                  ),
                  label: tr('most_common'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: CountUpNumber(
                    value: data.entriesThisMonth.toDouble(),
                    style: _valueStyle(context),
                  ),
                  label: tr('entries_short'),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: CountUpNumber(
                    value: data.wordsThisMonth.toDouble(),
                    compact: true,
                    thousandSuffix: tr('thousand_suffix'),
                    style: _valueStyle(context),
                  ),
                  label: tr('words_short'),
                ),
              ),
              Expanded(
                child: _Stat(
                  value: CountUpNumber(
                    value: data.writtenDays
                        .where((d) =>
                            d ~/ 10000 == data.month.year &&
                            (d ~/ 100) % 100 == data.month.month)
                        .length
                        .toDouble(),
                    style: _valueStyle(context),
                  ),
                  label: tr('days_written_short'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _valueStyle(BuildContext context) => TextStyle(
        fontFamily: AppTheme.displayFont,
        fontWeight: FontWeight.w800,
        fontSize: 25,
        letterSpacing: -0.5,
        color: Theme.of(context).colorScheme.onSurface,
      );
}

class _Stat extends StatelessWidget {
  final Widget value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        value,
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 11.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
