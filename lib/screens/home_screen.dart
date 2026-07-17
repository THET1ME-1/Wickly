import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/entry_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../widgets/empty_state.dart';
import '../widgets/reveal.dart';
import 'settings_screen.dart';

/// Главный экран (лента). Показывает записи из локального CRDT-хранилища живым
/// потоком. Кнопка «Новая запись» пока создаёт запись-заглушку — это временные
/// леса, чтобы видеть, что слой данных работает сквозняком; настоящий редактор
/// придёт следующим шагом.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _quickCreate() async {
    await EntryRepository.instance.insert(Entry.create(
      journalId: AppDatabase.defaultJournalId,
      title: tr('new_entry'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wickly'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: tr('settings'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: StreamBuilder<List<Entry>>(
        stream: EntryRepository.instance.watchEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <Entry>[];
          if (entries.isEmpty) {
            return EmptyState(
              icon: Icons.local_fire_department_rounded,
              title: tr('home_empty_title'),
              subtitle: tr('home_empty_sub'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: entries.length,
            itemBuilder: (context, i) => _EntryTile(entry: entries[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _quickCreate,
        icon: const Icon(Icons.edit_rounded),
        label: Text(tr('new_entry')),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final Entry entry;
  const _EntryTile({required this.entry});

  static String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} · '
        '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Reveal(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(Icons.delete_rounded, color: scheme.onErrorContainer),
          ),
          onDismissed: (_) => EntryRepository.instance.delete(entry.id),
          child: Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.notes_rounded,
                    color: scheme.onPrimaryContainer),
              ),
              title: Text(
                (entry.title == null || entry.title!.isEmpty)
                    ? tr('new_entry')
                    : entry.title!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_fmt(entry.entryDate)),
            ),
          ),
        ),
      ),
    );
  }
}
