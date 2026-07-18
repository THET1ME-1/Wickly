import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../data/entry_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../services/feed_service.dart';
import '../theme/wickly_design.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_card.dart';
import 'lock_screen.dart';
import 'reader_screen.dart';

/// Скрытые записи — за замком, даже если весь дневник открыт.
///
/// Смысл раздела в том, что эти записи не показываются нигде: ни в ленте, ни
/// в поиске, ни в календаре. Поэтому вход сюда всегда спрашивает код, если он
/// задан, — иначе «скрытая» ничем не отличалась бы от обычной.
class HiddenEntriesScreen extends StatefulWidget {
  const HiddenEntriesScreen({super.key});

  @override
  State<HiddenEntriesScreen> createState() => _HiddenEntriesScreenState();
}

class _HiddenEntriesScreenState extends State<HiddenEntriesScreen> {
  late bool _unlocked = !AppPrefs.instance.hasPin;
  List<EntryCardItem> _items = const [];

  @override
  void initState() {
    super.initState();
    if (_unlocked) _load();
  }

  Future<void> _load() async {
    final all = await EntryRepository.instance.allEntries(includeHidden: true);
    final hidden = all.where((e) => e.hidden).toList();
    final items = await FeedService.decorate(hidden);
    if (mounted) setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return LockScreen(
        onUnlocked: () {
          setState(() => _unlocked = true);
          _load();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tr('hidden_entries'))),
      body: _items.isEmpty
          ? EmptyState(
              icon: Icons.visibility_off_rounded,
              title: tr('hidden_empty_title'),
              subtitle: tr('hidden_empty_sub'),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 8,
                  WicklyDesign.screenPad, 24),
              itemCount: _items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: WicklyDesign.gapCards),
              itemBuilder: (context, i) => EntryCard(
                item: _items[i],
                onTap: () => _open(_items[i].entry),
              ),
            ),
    );
  }

  Future<void> _open(Entry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReaderScreen(entryId: entry.id)),
    );
    await _load();
  }
}
