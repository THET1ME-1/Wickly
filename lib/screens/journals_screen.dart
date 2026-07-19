import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// Дневник вместе со счётчиком записей.
class JournalTile {
  final Journal journal;
  final int count;

  const JournalTile({required this.journal, required this.count});
}

/// Дневники: «Личное», «Путешествия», «Благодарность».
///
/// Обложки крупные и цветные — дневник узнаётся по цвету раньше, чем читается
/// имя. Запертый помечен замком: видно, что он есть, но не видно, что внутри.
class JournalsView extends StatelessWidget {
  final List<JournalTile> journals;
  final void Function(Journal journal)? onOpen;
  final void Function(Journal journal)? onEdit;
  final VoidCallback? onCreate;

  const JournalsView({
    super.key,
    required this.journals,
    this.onOpen,
    this.onEdit,
    this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('journals')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: onCreate,
            tooltip: tr('new_journal'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GridView.count(
        // На широком окне обложки становятся в ряд по ширине, а не по две:
        // растянутая на полстола карточка дневника выглядит нелепо.
        crossAxisCount: WicklyDesign.gridColumns(context, 280),
        padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 8,
            WicklyDesign.screenPad, 28),
        crossAxisSpacing: WicklyDesign.gapCards,
        mainAxisSpacing: WicklyDesign.gapCards,
        childAspectRatio: 0.92,
        children: [
          for (var i = 0; i < journals.length; i++)
            Reveal(
              delay: Duration(milliseconds: 40 * (i < 5 ? i : 5)),
              child: _JournalCard(
                tile: journals[i],
                onTap: () => onOpen?.call(journals[i].journal),
                onLongPress: () => onEdit?.call(journals[i].journal),
              ),
            ),
          _NewJournalCard(onTap: onCreate),
        ],
      ),
    );
  }
}

/// Обложка дневника: градиент, имя, счётчик и замок у запертого.
class _JournalCard extends StatelessWidget {
  final JournalTile tile;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _JournalCard({required this.tile, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final j = tile.journal;
    return PressableScale(
      child: Material(
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: CoverPalette.gradient(j.cover),
            borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
          ),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Stack(
              children: [
                // Затемнение снизу: белые буквы должны читаться на любом градиенте.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x73000000)],
                        stops: [0.45, 1],
                      ),
                    ),
                  ),
                ),
                if (j.locked)
                  const Positioned(
                    right: 12,
                    top: 12,
                    child: _LockBadge(),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (j.icon != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Icon(AppIcons.resolve(j.icon),
                              size: 18, color: Colors.white70),
                        ),
                      // Длинное имя ужимаем, а не переносим посреди слова:
                      // «Путешестви/я» на обложке читается как опечатка.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          j.name,
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        j.locked
                            ? tr('journal_locked')
                            : Dates.entryCount(tile.count),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12.5,
                          color: Color(0xCCFFFFFF),
                        ),
                      ),
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

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Color(0x59000000),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock_rounded, size: 15, color: Colors.white),
      );
}

/// Пустая карточка «＋ Новый дневник».
class _NewJournalCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _NewJournalCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
              border: Border.all(color: scheme.outlineVariant, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: scheme.onSurfaceVariant),
                const SizedBox(height: 6),
                Text(
                  tr('new_journal'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
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
