import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_card.dart';
import '../widgets/media_thumb.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// «В этот день»: записи этой же даты в прошлые годы.
///
/// Свежее воспоминание — крупной карточкой, остальные годы — компактным
/// столбцом: обычно человек хочет перечитать последнее, а остальные пробежать
/// глазами.
class MemoriesView extends StatelessWidget {
  /// Воспоминания, свежие сверху.
  final List<EntryCardItem> memories;

  final DateTime day;
  final void Function(Entry entry)? onOpen;
  final VoidCallback? onShare;

  const MemoriesView({
    super.key,
    required this.memories,
    required this.day,
    this.onOpen,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final years = memories.map((m) => m.entry.entryDate.year).toSet().length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: WicklyDesign.screenPad,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('on_this_day'),
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '${Dates.dayMonth(day)} · ${Dates.memoryYears(years)}',
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: onShare,
            tooltip: tr('share_entry'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: memories.isEmpty
          ? EmptyState(
              icon: Icons.history_rounded,
              title: tr('memories_empty_title'),
              subtitle: tr('memories_empty_sub'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 4,
                  WicklyDesign.screenPad, 28),
              children: [
                Reveal(
                  child: _BigMemory(
                    item: memories.first,
                    onTap: () => onOpen?.call(memories.first.entry),
                  ),
                ),
                const SizedBox(height: 6),
                for (var i = 1; i < memories.length; i++)
                  Reveal(
                    delay: Duration(milliseconds: 50 * (i < 5 ? i : 5)),
                    child: _YearRow(
                      item: memories[i],
                      onTap: () => onOpen?.call(memories[i].entry),
                    ),
                  ),
              ],
            ),
    );
  }

}

/// Крупная карточка свежего воспоминания.
class _BigMemory extends StatelessWidget {
  final EntryCardItem item;
  final VoidCallback? onTap;

  const _BigMemory({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = item.entry;
    final years = DateTime.now().year - e.entryDate.year;

    return PressableScale(
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaThumb(
                      media: item.cover,
                      coverKey: CoverPalette.forSeed(e.id),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x8C000000),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          '${Dates.yearsAgo(years)} · ${e.entryDate.year}',
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(WicklyDesign.gapInside),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title?.trim().isNotEmpty == true
                          ? e.title!
                          : tr('entry_untitled'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.3,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      EntryCard.previewOf(e),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (e.mood != null)
                          _MiniChip(
                            dotColor: MoodPaletteX.of(context, e.mood),
                            label: MoodPaletteX.label(e.mood!),
                          ),
                        if (e.place != null)
                          _MiniChip(
                              icon: Icons.place_rounded, label: e.place!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Компактная строка воспоминания: год слева, запись справа.
class _YearRow extends StatelessWidget {
  final EntryCardItem item;
  final VoidCallback? onTap;

  const _YearRow({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = item.entry;
    final years = DateTime.now().year - e.entryDate.year;

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 62,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.entryDate.year}',
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.5,
                          color: scheme.primary,
                        ),
                      ),
                      Text(
                        Dates.yearsAgo(years),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title?.trim().isNotEmpty == true
                                    ? e.title!
                                    : tr('entry_untitled'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.displayFont,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                EntryCard.previewOf(e),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 12.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (e.mood != null) ...[
                          const SizedBox(width: 10),
                          MoodDot(mood: e.mood, size: 12),
                        ],
                      ],
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

class _MiniChip extends StatelessWidget {
  final IconData? icon;
  final Color? dotColor;
  final String label;

  const _MiniChip({this.icon, this.dotColor, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 9,
              height: 9,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
