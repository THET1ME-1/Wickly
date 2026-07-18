import 'package:flutter/material.dart';

import '../data/journal_repository.dart';
import '../models/entry.dart';
import '../widgets/journal_editor_sheet.dart';
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
    await _load();
  }

  Future<void> _edit(Journal journal) async {
    await showJournalEditor(context, journal: journal);
    await _load();
  }

  @override
  Widget build(BuildContext context) => JournalsView(
        journals: _tiles,
        onCreate: _create,
        onEdit: _edit,
        onOpen: (j) {
          if (widget.onPick != null) {
            widget.onPick!(j);
          } else {
            _edit(j);
          }
        },
      );
}
