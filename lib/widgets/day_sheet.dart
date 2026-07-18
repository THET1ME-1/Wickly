import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import 'entry_card.dart';
import 'sheet_scaffold.dart';

/// Лист дня из календаря: что было в этот день и кнопка написать.
///
/// Раньше тап по дате открывал первую запись дня и молчал про остальные, а
/// пустой день не открывал ничего — с календаря нельзя было начать запись.
Future<Entry?> showDaySheet(
  BuildContext context, {
  required DateTime day,
  required List<EntryCardItem> items,
  required VoidCallback onWrite,
}) =>
    showWicklySheet<Entry>(
      context,
      builder: (_) => _DaySheet(day: day, items: items, onWrite: onWrite),
    );

class _DaySheet extends StatelessWidget {
  final DateTime day;
  final List<EntryCardItem> items;
  final VoidCallback onWrite;

  const _DaySheet({
    required this.day,
    required this.items,
    required this.onWrite,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moods = items.map((i) => i.entry.mood).whereType<int>().toList();
    final mood = moods.isEmpty
        ? null
        : (moods.reduce((a, b) => a + b) / moods.length).round();

    return SheetScaffold(
      title: Dates.dayLong(day),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            WicklyDesign.screenPad, 0, WicklyDesign.screenPad, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  tr('day_empty'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  if (mood != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: MoodPaletteX.of(context, mood),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    Dates.entryCount(items.length),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Дней с десятком записей не бывает, но лист не должен вырасти
              // выше экрана — поэтому прокрутка по содержимому.
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: WicklyDesign.gapCards),
                  itemBuilder: (context, i) => EntryCard(
                    item: items[i],
                    onTap: () => Navigator.of(context).pop(items[i].entry),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onWrite();
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(tr('day_write')),
            ),
          ],
        ),
      ),
    );
  }
}
