import 'package:flutter/material.dart';

import '../data/tracker_repository.dart';
import '../l10n/strings.dart';
import '../models/catalog.dart';
import '../services/habit_stats.dart';
import '../theme/app_theme.dart';
import '../theme/feedback.dart';
import '../theme/icon_keys.dart';
import '../theme/wickly_design.dart';
import '../utils/catalog_names.dart';
import '../widgets/count_up_number.dart';
import '../widgets/habit_heatmap.dart';
import '../widgets/reveal.dart';
import '../widgets/tracker_editor_sheet.dart';

/// Экран одной привычки: серия, поле выполнения и статистика.
///
/// В списке трекеров у привычки была одна строка с семью кружками — по ней
/// не видно ни серии, ни того, как шёл месяц. Здесь привычка показана целиком.
class HabitScreen extends StatefulWidget {
  final Tracker tracker;

  const HabitScreen({super.key, required this.tracker});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen> {
  /// Сколько дней истории показываем. Пятнадцать недель влезают в ширину
  /// телефона клеткой приличного размера.
  static const _historyDays = 15 * 7;

  late Tracker _tracker = widget.tracker;
  Map<int, double> _byDay = const {};
  HabitStats _stats = HabitStats.empty;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 400));
    final byDay =
        await TrackerRepository.instance.range(_tracker.id, from, now);
    if (!mounted) return;
    setState(() {
      _byDay = byDay;
      _stats = HabitMath.of(byDay, now: now, expectedOn: _tracker.expectedOn);
      _loading = false;
    });
  }

  Future<void> _toggle(int daysAgo) async {
    final day = DateTime.now().subtract(Duration(days: daysAgo));
    final done = HabitMath.done(_byDay, day);
    await TrackerRepository.instance.setValue(_tracker.id, day, done ? 0 : 1);
    await _load();
  }

  Future<void> _toggleToday() async {
    final done = HabitMath.done(_byDay, DateTime.now());
    done ? Haptics.tap() : Haptics.celebrate();
    await _toggle(0);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint =
        _tracker.color == null ? scheme.primary : Color(_tracker.color!);
    final doneToday = HabitMath.done(_byDay, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(CatalogNames.of(_tracker)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: tr('edit'),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await showTrackerEditor(context, tracker: _tracker);
              final fresh = (await TrackerRepository.instance.trackers())
                  .where((t) => t.id == _tracker.id)
                  .firstOrNull;
              if (!mounted) return;
              // Привычку могли удалить из редактора — показывать нечего.
              if (fresh == null) {
                navigator.pop();
                return;
              }
              setState(() => _tracker = fresh);
              await _load();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 4,
                  WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 28),
              children: [
                Reveal(child: _todayCard(scheme, tint, doneToday)),
                const SizedBox(height: WicklyDesign.gapCards),
                Reveal(
                  delay: WicklyDesign.revealDelay(1),
                  child: _card(
                    scheme,
                    title: tr('habit_history'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HabitHeatmap(
                          days: HabitMath.history(_byDay, days: _historyDays),
                          color: tint,
                          expectedOn: _tracker.expectedOn,
                          onToggle: _toggle,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr('habit_history_hint'),
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 11.5,
                            height: 1.35,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: WicklyDesign.gapCards),
                Reveal(
                  delay: WicklyDesign.revealDelay(2),
                  child: _card(
                    scheme,
                    title: tr('habit_stats'),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _stat(scheme, _stats.streak.toDouble(),
                                  tr('habit_streak')),
                            ),
                            Expanded(
                              child: _stat(scheme, _stats.best.toDouble(),
                                  tr('habit_best')),
                            ),
                            Expanded(
                              child: _stat(scheme, _stats.total.toDouble(),
                                  tr('habit_total')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _rateBar(scheme, tint),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Главная карточка: одна большая кнопка «сделал сегодня».
  Widget _todayCard(ColorScheme scheme, Color tint, bool done) => Material(
        color: done ? tint.withValues(alpha: 0.18) : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleToday,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: AppTheme.emphasized,
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: done ? tint : scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    done
                        ? Icons.check_rounded
                        : AppIcons.resolve(_tracker.icon),
                    size: 28,
                    color: done ? scheme.surface : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done ? tr('habit_done_today') : tr('habit_mark_today'),
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _stats.streak > 0
                            ? trf('habit_streak_days', {'n': _stats.streak})
                            : tr('habit_no_streak'),
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _card(ColorScheme scheme,
          {required String title, required Widget child}) =>
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
              title,
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _stat(ColorScheme scheme, double value, String label) => Column(
        children: [
          CountUpNumber(
            value: value,
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );

  /// Доля выполнения за месяц — полосой, а не числом: так видно «сколько ещё».
  Widget _rateBar(ColorScheme scheme, Color tint) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _tracker.weekdays == 0
                      ? tr('habit_rate_30')
                      : trf('habit_rate_schedule',
                          {'n': _tracker.daysPerWeek}),
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${_stats.last30} / ${_stats.expected30}',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _stats.rate30),
              duration: const Duration(milliseconds: 620),
              curve: AppTheme.emphasizedDecelerate,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHighest,
                color: tint,
                stopIndicatorColor: Colors.transparent,
              ),
            ),
          ),
        ],
      );
}
