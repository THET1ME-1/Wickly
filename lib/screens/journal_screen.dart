import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../data/entry_repository.dart';
import '../data/journal_lock.dart';
import '../data/journal_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../services/feed_service.dart';
import '../theme/app_theme.dart';
import '../theme/icon_keys.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_card.dart';
import '../widgets/journal_editor_sheet.dart';
import '../widgets/reveal.dart';
import 'editor_screen.dart';
import 'reader_screen.dart';

/// Записи одного дневника.
///
/// До этого экрана дневник был только папкой без дна: тап по обложке открывал
/// правку имени и цвета, а посмотреть, что внутри, было негде — записи
/// запертого дневника вообще не показывались нигде. Здесь дневник читается: его
/// обложка, его записи, его же кнопка «написать».
class JournalScreen extends StatefulWidget {
  final Journal journal;

  const JournalScreen({super.key, required this.journal});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Journal _journal = widget.journal;
  List<EntryCardItem> _items = const [];
  bool _loading = true;

  /// Что уже показывали — каскад не должен повторяться при прокрутке.
  final Set<Object> _shown = <Object>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await EntryRepository.instance.byJournal(_journal.id);
    final items = await FeedService.decorate(entries);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _write() async {
    // Записал в этот дневник — сюда же и вернётся кнопка «＋» в ленте.
    await AppPrefs.instance.setLastJournal(_journal.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditorScreen(journalId: _journal.id),
    ));
    await _load();
  }

  Future<void> _open(Entry entry) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(
        entryId: entry.id,
        onEdit: (e) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EditorScreen(entry: e, journalId: e.journalId),
        )),
      ),
    ));
    await _load();
  }

  Future<void> _edit() async {
    await showJournalEditor(context, journal: _journal);
    // Замок могли включить или снять прямо сейчас — список запертых обновляем
    // до перезагрузки, иначе выборки отработают по старому.
    await JournalLock.refresh();
    final fresh = await JournalRepository.instance.getById(_journal.id);
    if (!mounted) return;
    // Дневник удалили из его же правки — показывать больше нечего.
    if (fresh == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _journal = fresh);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _write,
        icon: const Icon(Icons.edit_rounded),
        label: Text(tr('write')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 168,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: _edit,
                tooltip: tr('edit'),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: _Cover(journal: _journal, count: _items.length),
          ),
          if (_loading)
            const SliverToBoxAdapter(child: SizedBox.shrink())
          else if (_items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.menu_book_rounded,
                title: tr('journal_empty_title'),
                subtitle: tr('journal_empty_sub'),
              ),
            )
          else
            SliverList.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: WicklyDesign.gapCards),
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.fromLTRB(
                  WicklyDesign.screenPad,
                  i == 0 ? 12 : 0,
                  WicklyDesign.screenPad,
                  i == _items.length - 1 ? 96 : 0,
                ),
                child: Reveal(
                  group: _shown,
                  id: _items[i].entry.id,
                  delay: WicklyDesign.revealDelay(i),
                  child: EntryCard(
                    item: _items[i],
                    onTap: () => _open(_items[i].entry),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Шапка экрана — та же обложка, по которой дневник узнают в сетке.
class _Cover extends StatelessWidget {
  final Journal journal;
  final int count;

  const _Cover({required this.journal, required this.count});

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (journal.icon != null) ...[
            Icon(AppIcons.resolve(journal.icon), size: 16, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              journal.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (journal.locked) ...[
            const SizedBox(width: 6),
            const Icon(Icons.lock_open_rounded, size: 15, color: Colors.white70),
          ],
        ],
      ),
      background: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: CoverPalette.gradient(journal.cover),
            ),
          ),
          // Затемнение снизу: белые буквы должны читаться на любом градиенте.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x8C000000)],
                stops: [0.4, 1],
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 44,
            child: Text(
              Dates.entryCount(count),
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12.5,
                color: Color(0xCCFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
