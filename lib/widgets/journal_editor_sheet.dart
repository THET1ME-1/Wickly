import 'package:flutter/material.dart';

import '../data/journal_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import 'icon_picker_sheet.dart';
import 'journal_password_sheet.dart';
import 'sheet_scaffold.dart';

/// Заводит или правит дневник: имя, обложка, иконка и замок.
Future<Journal?> showJournalEditor(
  BuildContext context, {
  Journal? journal,
  int sort = 0,
}) =>
    showWicklySheet<Journal>(
      context,
      builder: (_) => _JournalEditor(journal: journal, sort: sort),
    );

class _JournalEditor extends StatefulWidget {
  final Journal? journal;
  final int sort;

  const _JournalEditor({this.journal, required this.sort});

  @override
  State<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<_JournalEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.journal?.name ?? '');
  late String _cover = widget.journal?.cover ?? CoverPalette.fallback;
  late String _icon = widget.journal?.icon ?? 'book';
  late bool _locked = widget.journal?.locked ?? false;

  // Пароль правится здесь же, но в базу уходит только вместе с «Сохранить»:
  // передумал на полпути — дневник остался прежним.
  late String? _passHash = widget.journal?.passHash;
  late String? _passSalt = widget.journal?.passSalt;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Замок включают паролем: тумблер без пароля запирал бы дневник на дверь,
  /// у которой нет ключа.
  Future<void> _toggleLock(bool on) async {
    if (!on) {
      setState(() {
        _locked = false;
        _passHash = null;
        _passSalt = null;
      });
      return;
    }
    if (_passHash != null) {
      setState(() => _locked = true);
      return;
    }
    await _askPassword();
  }

  Future<void> _askPassword() async {
    final created = await askNewJournalPassword(context);
    if (created == null || !mounted) return;
    setState(() {
      _locked = true;
      _passHash = created.hash;
      _passSalt = created.salt;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final repo = JournalRepository.instance;
    final saved = widget.journal == null
        ? Journal.create(
            name: name, cover: _cover, icon: _icon, locked: _locked,
            sort: widget.sort, passHash: _passHash, passSalt: _passSalt)
        : widget.journal!.copyWith(
            name: name,
            cover: _cover,
            icon: _icon,
            locked: _locked,
            passHash: _passHash,
            passSalt: _passSalt,
            clearPass: _passHash == null,
          );
    if (widget.journal == null) {
      await repo.insert(saved);
    } else {
      await repo.update(saved);
    }
    if (mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _delete() async {
    final journal = widget.journal;
    if (journal == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(trf('delete_journal_q', {'name': journal.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('delete'),
                style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await JournalRepository.instance.delete(journal.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SheetScaffold(
      title: widget.journal == null ? tr('new_journal') : tr('edit'),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      action: widget.journal == null
          ? null
          : IconButton(
              icon: Icon(Icons.delete_rounded, color: scheme.error),
              onPressed: _delete,
            ),
      bottom: FilledButton(onPressed: _save, child: Text(tr('save'))),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Предпросмотр обложки — выбирают её глазами, а не по названию.
            Container(
              height: 96,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: CoverPalette.gradient(_cover),
                borderRadius: BorderRadius.circular(WicklyDesign.radiusCover),
              ),
              padding: const EdgeInsets.all(14),
              alignment: Alignment.bottomLeft,
              child: Text(
                _name.text.trim().isEmpty ? tr('new_journal') : _name.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: widget.journal == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: tr('name')),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(tr('cover'), style: _label(scheme)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final key in CoverPalette.keys)
                  GestureDetector(
                    onTap: () => setState(() => _cover = key),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: CoverPalette.gradient(key),
                        borderRadius: BorderRadius.circular(14),
                        border: _cover == key
                            ? Border.all(color: scheme.onSurface, width: 2.5)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(tr('icon'), style: _label(scheme)),
            const SizedBox(height: 8),
            IconChoiceGrid(
              selected: _icon,
              tint: scheme.primary,
              count: 16,
              onPick: (key) => setState(() => _icon = key),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _locked,
              onChanged: _toggleLock,
              title: Text(tr('journal_lock'), style: _label(scheme)),
              subtitle: Text(
                tr('journal_lock_sub'),
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (_locked && _passHash != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _askPassword,
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: Text(tr('journal_password_change')),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  TextStyle _label(ColorScheme scheme) => TextStyle(
        fontFamily: AppTheme.displayFont,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: scheme.onSurface,
      );
}
