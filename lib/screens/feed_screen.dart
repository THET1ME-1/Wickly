import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/entry.dart';
import '../services/stats_service.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_card.dart';
import '../widgets/media_thumb.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// Всё, что показывает лента. Собирается снаружи (экран-контейнер), поэтому сам
/// вид чистый и снимается в тестах без базы.
class FeedData {
  final List<EntryCardItem> items;
  final Streak streak;

  /// Записи с этой же датой прошлых лет.
  final List<EntryCardItem> memories;

  /// Заголовок периода: «июль 2026».
  final String period;

  /// Какие из последних семи дней с записью (свежий день — последний).
  /// Точки серии показывают именно это, а не просто счётчик: так видно, где
  /// был пропуск.
  final List<bool> lastWeek;

  /// «Сегодня» приходит снаружи: экран не спрашивает часы сам, поэтому его
  /// снимок не меняется от запуска к запуску.
  final DateTime now;

  const FeedData({
    required this.items,
    required this.streak,
    this.memories = const [],
    required this.period,
    this.lastWeek = const [],
    required this.now,
  });
}

/// Лента: серия дней, воспоминание «в этот день» и записи, сгруппированные по
/// дням.
///
/// Это главный экран, поэтому он отвечает на два вопроса сразу: «что я писал»
/// и «пишу ли я вообще». Серия и воспоминание стоят выше записей — они и
/// возвращают человека в дневник.
class FeedView extends StatefulWidget {
  final FeedData data;
  final void Function(Entry entry)? onOpenEntry;
  final VoidCallback? onWrite;
  final VoidCallback? onSearch;
  final VoidCallback? onMenu;
  final VoidCallback? onOpenMemories;
  final VoidCallback? onOpenStreak;

  const FeedView({
    super.key,
    required this.data,
    this.onOpenEntry,
    this.onWrite,
    this.onSearch,
    this.onMenu,
    this.onOpenMemories,
    this.onOpenStreak,
  });

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  /// Уже показанные карточки — чтобы появление не переигрывалось на скролле.
  final _revealed = <String>{};

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = widget.data;
    final groups = _groupByDay(data.items);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onWrite,
        icon: const Icon(Icons.edit_rounded),
        label: Text(tr('write')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 104,
            backgroundColor: scheme.surface,
            surfaceTintColor: Colors.transparent,
            title: null,
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: tr('search'),
                onPressed: widget.onSearch,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: widget.onMenu,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: WicklyDesign.screenPad, bottom: 14),
              expandedTitleScale: 1.35,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('tab_feed'),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.3,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0),
              child: Container(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  WicklyDesign.screenPad, 0, WicklyDesign.screenPad, 4),
              child: Text(
                '${data.period} · ${Dates.entryCount(data.items.length)}',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

          if (data.items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.local_fire_department_rounded,
                title: tr('feed_empty_title'),
                subtitle: tr('feed_empty_sub'),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 10,
                    WicklyDesign.screenPad, 0),
                child: Column(
                  children: [
                    Reveal(
                      child: _StreakCard(
                        streak: data.streak,
                        lastWeek: data.lastWeek,
                        onTap: widget.onOpenStreak,
                      ),
                    ),
                    if (data.memories.isNotEmpty) ...[
                      const SizedBox(height: WicklyDesign.gapCards),
                      Reveal(
                        delay: const Duration(milliseconds: 70),
                        child: _MemoryCard(
                          item: data.memories.first,
                          onTap: widget.onOpenMemories,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            for (final group in groups) ...[
              SliverToBoxAdapter(
                child: _DayHeader(
                  day: group.day,
                  mood: group.mood,
                  now: data.now,
                ),
              ),
              SliverList.separated(
                itemCount: group.items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: WicklyDesign.gapCards),
                itemBuilder: (context, i) {
                  final item = group.items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: WicklyDesign.screenPad),
                    child: Reveal(
                      group: _revealed,
                      id: item.entry.id,
                      delay: Duration(milliseconds: 40 * (i < 4 ? i : 4)),
                      child: EntryCard(
                        item: item,
                        onTap: () => widget.onOpenEntry?.call(item.entry),
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ],
      ),
    );
  }

  static List<_DayGroup> _groupByDay(List<EntryCardItem> items) {
    final byDay = <int, List<EntryCardItem>>{};
    for (final item in items) {
      final d = item.entry.entryDate;
      (byDay[d.year * 10000 + d.month * 100 + d.day] ??= []).add(item);
    }
    final keys = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final key in keys)
        _DayGroup(
          day: DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100),
          items: byDay[key]!,
        ),
    ];
  }
}

class _DayGroup {
  final DateTime day;
  final List<EntryCardItem> items;

  const _DayGroup({required this.day, required this.items});

  /// Настроение дня — среднее по записям, округлённое до ступени.
  int? get mood {
    final moods = items
        .map((i) => i.entry.mood)
        .whereType<int>()
        .toList();
    if (moods.isEmpty) return null;
    return (moods.reduce((a, b) => a + b) / moods.length).round();
  }
}

/// Заголовок дня: «СЕГОДНЯ · ЧТ 17 ИЮЛЯ» и кружок настроения справа.
class _DayHeader extends StatelessWidget {
  final DateTime day;
  final int? mood;
  final DateTime now;

  const _DayHeader({required this.day, this.mood, required this.now});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isToday = day.year == now.year &&
        day.month == now.month &&
        day.day == now.day;
    final label = isToday
        ? '${tr('today')} · ${Dates.dayShort(day)}'
        : Dates.dayShort(day);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          WicklyDesign.screenPad, 22, WicklyDesign.screenPad, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.8,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (mood != null) MoodDot(mood: mood, size: 12),
        ],
      ),
    );
  }
}

/// Серия дней: огонёк, счёт и семь точек последней недели.
class _StreakCard extends StatelessWidget {
  final Streak streak;
  final List<bool> lastWeek;
  final VoidCallback? onTap;

  const _StreakCard({
    required this.streak,
    required this.lastWeek,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final has = streak.current > 0;

    return PressableScale(
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_fire_department_rounded,
                      size: 21, color: scheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        has
                            ? Dates.daysStreak(streak.current)
                            : tr('streak_short'),
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            has ? tr('streak_keep') : tr('streak_start'),
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _WeekDots(days: lastWeek, streak: streak),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Семь точек: закрашенные — дни серии, последняя пустая — сегодня без записи.
class _WeekDots extends StatelessWidget {
  final List<bool> days;
  final Streak streak;

  const _WeekDots({required this.days, required this.streak});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const total = 7;
    // Если картину недели не передали — рисуем её из длины серии.
    final week = days.length == total
        ? days
        : [for (var i = 0; i < total; i++) i >= total - streak.current];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final written in week)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(left: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: written ? scheme.primary : scheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

/// «В этот день · 3 года назад» — цитата из прошлого и её обложка.
class _MemoryCard extends StatelessWidget {
  final EntryCardItem item;
  final VoidCallback? onTap;

  const _MemoryCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = item.entry;
    final years = DateTime.now().year - e.entryDate.year;
    final title = e.title?.trim();

    return PressableScale(
      child: Material(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history_rounded,
                              size: 15, color: scheme.onTertiaryContainer),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${tr('on_this_day')} · ${Dates.yearsAgo(years)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: scheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title != null && title.isNotEmpty
                            ? '«$title»'
                            : EntryCard.previewOf(e),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13.5,
                          height: 1.35,
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: MediaThumb(
                      media: item.cover,
                      coverKey: CoverPalette.forSeed(e.id),
                    ),
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
