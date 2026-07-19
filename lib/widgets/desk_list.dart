import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../utils/dates.dart';
import 'entry_card.dart';
import 'markdown_lite.dart';
import 'media_thumb.dart';

/// Чем сужен список.
enum DeskFilter { all, photo, favorite }

/// Список записей рядом с открытой записью («Разворот»).
///
/// Компактнее карточек ленты: в колонке 392 точки важнее увидеть много дней
/// сразу, чем обложку каждой записи. Дни разделены полосами — хронология не
/// теряется, а выбранная строка подсвечена, чтобы не терять место при чтении.
class DeskList extends StatefulWidget {
  final List<EntryCardItem> items;
  final String? selectedId;
  final void Function(EntryCardItem item) onOpen;
  final VoidCallback? onSearch;

  /// Дневник, выбранный в боковой панели: показывается снимаемым чипом.
  final String? journalFilter;
  final VoidCallback? onClearJournal;

  final double width;
  final DateTime? now;

  const DeskList({
    super.key,
    required this.items,
    required this.onOpen,
    this.selectedId,
    this.onSearch,
    this.journalFilter,
    this.onClearJournal,
    this.width = 392,
    this.now,
  });

  @override
  State<DeskList> createState() => _DeskListState();
}

class _DeskListState extends State<DeskList> {
  DeskFilter _filter = DeskFilter.all;

  List<EntryCardItem> get _visible => switch (_filter) {
        DeskFilter.all => widget.items,
        DeskFilter.photo =>
          widget.items.where((i) => i.mediaCount > 0 || i.cover != null).toList(),
        DeskFilter.favorite =>
          widget.items.where((i) => i.entry.favorite).toList(),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = widget.now ?? DateTime.now();
    final items = _visible;

    // Записи разложены по дням: заголовок дня — единственный ориентир в
    // колонке без обложек.
    final days = <int, List<EntryCardItem>>{};
    for (final i in items) {
      final d = i.entry.entryDate;
      (days[d.year * 10000 + d.month * 100 + d.day] ??= []).add(i);
    }
    final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                _SearchBox(onTap: widget.onSearch),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (widget.journalFilter != null) ...[
                      _FilterChip(
                        label: widget.journalFilter!,
                        on: true,
                        trailing: Icons.close_rounded,
                        onTap: widget.onClearJournal,
                      ),
                      const SizedBox(width: 6),
                    ],
                    _FilterChip(
                      label: tr('filter_all'),
                      on: _filter == DeskFilter.all,
                      onTap: () => setState(() => _filter = DeskFilter.all),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: tr('filter_photo'),
                      on: _filter == DeskFilter.photo,
                      onTap: () => setState(() => _filter = DeskFilter.photo),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: tr('favorites'),
                      on: _filter == DeskFilter.favorite,
                      onTap: () => setState(() => _filter = DeskFilter.favorite),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: keys.length,
              itemBuilder: (context, i) {
                final day = days[keys[i]]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DayBar(day: day.first.entry.entryDate, now: now),
                    for (final item in day)
                      _Row(
                        item: item,
                        on: item.entry.id == widget.selectedId,
                        onTap: () => widget.onOpen(item),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final VoidCallback? onTap;
  const _SearchBox({this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr('search_hint'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              'Ctrl F',
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: scheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool on;
  final IconData? trailing;
  final VoidCallback? onTap;

  const _FilterChip({
    required this.label,
    required this.on,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: on ? scheme.primary : scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 5),
                Icon(trailing, size: 13,
                    color: on ? scheme.onPrimary : scheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DateTime day;
  final DateTime now;

  const _DayBar({required this.day, required this.now});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final relative = Dates.relativeDay(day, now: now);
    final label = Dates.sameDay(day, now)
        ? '$relative · ${Dates.dayMonth(day)}'
        : Dates.dayWithWeekday(day);

    return Container(
      width: double.infinity,
      color: scheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
          letterSpacing: 0.9,
          color: scheme.outline,
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  final EntryCardItem item;
  final bool on;
  final VoidCallback onTap;

  const _Row({required this.item, required this.on, required this.onTap});

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final on = widget.on;
    final e = item.entry;
    final snippet = MarkdownLite.strip(e.body);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
      color: on
          ? scheme.surfaceContainerHigh
          : _hover
              ? scheme.surfaceContainer
              : Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: scheme.outlineVariant),
              left: BorderSide(
                color: on ? scheme.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(on ? 13 : 16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          Dates.time(e.entryDate),
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 11.5,
                            color: scheme.outline,
                          ),
                        ),
                        if (e.mood != null) ...[
                          const SizedBox(width: 7),
                          MoodDot(mood: e.mood, size: 7),
                        ],
                        if (e.pinned) ...[
                          const SizedBox(width: 7),
                          Icon(Icons.push_pin_rounded,
                              size: 12, color: scheme.outline),
                        ],
                        if (e.favorite) ...[
                          const SizedBox(width: 7),
                          Icon(Icons.favorite_rounded,
                              size: 11, color: scheme.outline),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      EntryCard.titleOf(e),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (snippet.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        snippet,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12.5,
                          height: 1.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
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

class _Thumb extends StatelessWidget {
  final EntryCardItem item;
  const _Thumb({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final audio = item.cover == null &&
        item.entry.body != null &&
        item.mediaCount > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 56,
        height: 56,
        child: item.cover != null
            ? MediaThumb(media: item.cover)
            : ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: Icon(
                  audio ? Icons.mic_rounded : Icons.notes_rounded,
                  size: 20,
                  color: scheme.outline,
                ),
              ),
      ),
    );
  }
}
