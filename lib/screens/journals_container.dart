import 'package:flutter/material.dart';

import '../data/journal_lock.dart';
import '../data/journal_repository.dart';
import '../models/entry.dart';
import '../widgets/journal_editor_sheet.dart';
import '../widgets/journal_gate.dart';
import 'journal_screen.dart';
import 'journals_screen.dart';

/// Дневники с настоящими данными.
class JournalsContainer extends StatefulWidget {
  /// Что делать при выборе дневника. По умолчанию — просто закрыть экран
  /// и вернуть его id вызывающему.
  final void Function(Journal journal)? onPick;

  const JournalsContainer({super.key, this.onPick});

  @override
  State<JournalsContainer> createState() => _JournalsContainerState();
}

class _JournalsContainerState extends State<JournalsContainer> {
  List<JournalTile> _tiles = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final journals = await JournalRepository.instance.all();
    final counts = await JournalRepository.instance.counts();
    if (!mounted) return;
    setState(() => _tiles = [
          for (final j in journals)
            JournalTile(journal: j, count: counts[j.id] ?? 0),
        ]);
  }

  Future<void> _create() async {
    await showJournalEditor(context, sort: _tiles.length);
    // Новый дневник могли сразу завести под паролем.
    await JournalLock.refresh();
    await _load();
  }

  /// Правка дневника — тоже за замком: иначе долгий тап по запертой обложке
  /// открывал настройки, где замок снимается тумблером.
  Future<void> _edit(Journal journal) async {
    if (!await openJournalGate(context, journal)) return;
    if (!mounted) return;
    await showJournalEditor(context, journal: journal);
    // Замок могли включить или снять прямо сейчас — список запертых обновляем
    // до перезагрузки, иначе выборки отработают по старому.
    await JournalLock.refresh();
    await _load();
  }

  /// Открывает дневник: его записи, а не его настройки. Запертый сначала
  /// спрашивает свой пароль.
  Future<void> _open(Journal journal) async {
    if (!await openJournalGate(context, journal)) return;
    if (!mounted) return;
    if (widget.onPick != null) {
      widget.onPick!(journal);
      return;
    }
    // Пароль мог только что появиться (у старого дневника его не было) —
    // берём дневник заново, чтобы экран не держал устаревшую копию.
    final fresh =
        await JournalRepository.instance.getById(journal.id) ?? journal;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => JournalScreen(journal: fresh)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => JournalsView(
        journals: _tiles,
        onCreate: _create,
        onEdit: _edit,
        onOpen: _open,
      );
}
