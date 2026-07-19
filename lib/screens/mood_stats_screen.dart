import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/count_up_number.dart';
import '../widgets/empty_state.dart';
import '../widgets/mood_chart.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// Период статистики.
enum StatsRange { week, month, year }

/// Всё, что показывает статистика настроения.
class MoodStatsData {
  final MoodSummary summary;
  final Streak streak;

  /// Значения тренда по дням периода; `null` — день без настроения.
  final List<double?> trend;

  final List<Correlation> byWeather;
  final List<Correlation> byActivity;

  /// Подписи под графиком.
  final String startLabel;
  final String middleLabel;
  final String endLabel;

  const MoodStatsData({
    required this.summary,
    required this.streak,
    required this.trend,
    this.byWeather = const [],
    this.byActivity = const [],
    required this.startLabel,
    required this.middleLabel,
    required this.endLabel,
  });
}

/// Статистика настроения: тренд, корреляции и серии.
///
/// Смысл экрана — связи, а не цифры: «в ясные дни у меня 4,4, в дождь 3,1» —
/// это то, ради чего человек ведёт настроение. Поэтому корреляции стоят сразу
/// под графиком, а не прячутся вниз.
class MoodStatsView extends StatefulWidget {
  final MoodStatsData Function(StatsRange range) dataFor;
  final VoidCallback? onShare;
  final VoidCallback? onOpenStreak;

  const MoodStatsView({
    super.key,
    required this.dataFor,
    this.onShare,
    this.onOpenStreak,
  });

  @override
  State<MoodStatsView> createState() => _MoodStatsViewState();
}

class _MoodStatsViewState extends State<MoodStatsView> {
  StatsRange _range = StatsRange.month;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = widget.dataFor(_range);
    final empty = data.summary.daysWithMood == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('set_mood')),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: widget.onShare,
            tooltip: tr('share_entry'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 4,
            WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 28),
        children: [
          _RangeTabs(
            value: _range,
            onChange: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: 20),
          if (empty)
            EmptyState(
              icon: Icons.insights_rounded,
              title: tr('stats_empty_title'),
              subtitle: tr('stats_empty_sub'),
            )
          else ...[
            Reveal(child: _Average(data: data, range: _range)),
            const SizedBox(height: 14),
            Reveal(
              delay: const Duration(milliseconds: 60),
              child: MoodChart(
                values: data.trend,
                startLabel: data.startLabel,
                middleLabel: data.middleLabel,
                endLabel: data.endLabel,
              ),
            ),
            const SizedBox(height: 18),
            if (data.byWeather.isNotEmpty)
              Reveal(
                delay: const Duration(milliseconds: 120),
                child: _CorrelationCard(
                  icon: Icons.wb_sunny_rounded,
                  title: tr('mood_x_weather'),
                  rows: data.byWeather,
                ),
              ),
            if (data.byActivity.isNotEmpty) ...[
              const SizedBox(height: 12),
              Reveal(
                delay: const Duration(milliseconds: 160),
                child: _CorrelationCard(
                  icon: Icons.directions_run_rounded,
                  title: tr('mood_x_activity'),
                  rows: data.byActivity,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Reveal(
              delay: const Duration(milliseconds: 200),
              child: PressableScale(
                child: Material(
                  color: scheme.surfaceContainerHigh,
                  borderRadius:
                      BorderRadius.circular(WicklyDesign.radiusCard),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onOpenStreak,
                    child: Padding(
                      padding: const EdgeInsets.all(WicklyDesign.gapInside),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: scheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Dates.daysStreak(data.streak.current),
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  trf('streak_best', {'n': data.streak.best}),
                                  style: TextStyle(
                                    fontFamily: AppTheme.bodyFont,
                                    fontSize: 12.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: scheme.outline),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Крупное среднее и стрелка изменения против прошлого периода.
class _Average extends StatelessWidget {
  final MoodStatsData data;
  final StatsRange range;

  const _Average({required this.data, required this.range});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delta = data.summary.delta;
    final up = delta >= 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CountUpNumber(
          value: data.summary.average,
          fractionDigits: 1,
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontWeight: FontWeight.w800,
            fontSize: 40,
            height: 1,
            letterSpacing: -1,
            color: scheme.onSurface,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 5, left: 2),
          child: Text(
            '/5',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              trf('stats_average_for', {'period': _periodLabel(range)}),
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        // Показываем изменение, только когда есть с чем сравнивать.
        if (delta.abs() >= 0.05)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 15,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 5),
                Text(
                  '${up ? '+' : '−'}${delta.abs().toStringAsFixed(1)}',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _periodLabel(StatsRange range) => switch (range) {
        StatsRange.week => tr('range_week').toLowerCase(),
        StatsRange.month => tr('range_month').toLowerCase(),
        StatsRange.year => tr('range_year').toLowerCase(),
      };
}

/// Переключатель «Неделя · Месяц · Год».
class _RangeTabs extends StatelessWidget {
  final StatsRange value;
  final ValueChanged<StatsRange> onChange;

  const _RangeTabs({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          for (final r in StatsRange.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: AppTheme.emphasized,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: value == r
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    switch (r) {
                      StatsRange.week => tr('range_week'),
                      StatsRange.month => tr('range_month'),
                      StatsRange.year => tr('range_year'),
                    },
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: value == r
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «Настроение × погода»: полоски со средним по каждому значению.
class _CorrelationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Correlation> rows;

  const _CorrelationCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = rows.take(4).toList();

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
              Icon(icon, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final row in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      row.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: (row.average / 5).clamp(0, 1)),
                        duration: const Duration(milliseconds: 600),
                        curve: AppTheme.emphasizedDecelerate,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: MoodPalette.color(context, row.average.round()),
                          stopIndicatorColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 30,
                    child: Text(
                      row.average.toStringAsFixed(1).replaceAll('.', ','),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
