import 'package:flutter/material.dart';

import '../data/entry_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../services/wiki_links.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import 'markdown_lite.dart';
import 'sheet_scaffold.dart';

/// Выбор записи, на которую ставим ссылку.
///
/// Отдаёт заголовок, а не запись: в тексте ссылка живёт названием
/// (`[[Вечер у реки]]`), и переписать её потом можно руками.
Future<String?> pickEntryLink(BuildContext context, {String? exceptId}) =>
    showWicklySheet<String>(
      context,
      expand: true,
      builder: (_) => _EntryPicker(exceptId: exceptId),
    );

class _EntryPicker extends StatefulWidget {
  final String? exceptId;
  const _EntryPicker({this.exceptId});

  @override
  State<_EntryPicker> createState() => _EntryPickerState();
}

class _EntryPickerState extends State<_EntryPicker> {
  final _query = TextEditingController();
  List<Entry> _all = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await EntryRepository.instance.allEntries(includeDrafts: false);
    if (mounted) setState(() => _all = all);
  }

  /// Записи, на которые можно сослаться: у цели должно быть название, и на
  /// себя ссылаться незачем.
  List<({Entry entry, String title})> get _options {
    final q = _query.text.trim().toLowerCase();
    final out = <({Entry entry, String title})>[];
    for (final e in _all) {
      if (e.id == widget.exceptId) continue;
      final title = WikiLinks.titleOf(e);
      if (title == null) continue;
      if (q.isNotEmpty && !title.toLowerCase().contains(q)) continue;
      out.add((entry: e, title: title));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = _options;

    return SheetScaffold(
      title: tr('link_entry'),
      expand: true,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _query,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: tr('link_search'),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
              ),
            ),
          ),
          Expanded(
            child: options.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        tr('link_nothing'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final o = options[i];
                      final preview = MarkdownLite.strip(o.entry.body);
                      return ListTile(
                        title: Text(
                          o.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.displayFont,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: scheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${Dates.dayMonth(o.entry.entryDate)} · $preview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(o.title),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
