import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import '../data/app_prefs.dart';
import '../data/db_key.dart';
import '../data/entry_repository.dart';
import '../l10n/strings.dart';
import '../data/system_pause.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';
import '../widgets/settings_scaffold.dart';

/// Экспорт и бэкап.
///
/// Наверху то, ради чего сюда заходят чаще всего — собрать книгу за год.
/// Ниже форматы «унести с собой» и отдельно шифрованный бэкап: у них разные
/// задачи, и путать их нельзя.
class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('export_failed'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFile(File file, String label) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: label),
    );
  }

  Future<void> _book() => _run(() async {
        final entries = await EntryRepository.instance.allEntries();
        final bytes = await ExportService.toPdfBook(
          entries.reversed.toList(),
          title: tr('pdf_book_title'),
        );
        final file = await ExportService.writeTemp('wickly-book.pdf', bytes);
        await _shareFile(file, tr('pdf_book'));
      });

  /// Печать книги. Системный диалог сам предложит и принтер, и «в PDF».
  Future<void> _print() => _run(() async {
        final entries = await EntryRepository.instance.allEntries();
        final bytes = await ExportService.toPdfBook(
          entries.reversed.toList(),
          title: tr('pdf_book_title'),
        );
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      });

  Future<void> _markdown() => _run(() async {
        final entries = await EntryRepository.instance.allEntries();
        final file = await ExportService.writeTemp(
          'wickly.md',
          // utf8, а не codeUnits: у кириллицы код больше 255, и запись
          // байтами резала каждый символ до младшего байта — файл выходил
          // нечитаемым, причём молча.
          utf8.encode(ExportService.toMarkdown(entries.reversed.toList())),
        );
        await _shareFile(file, 'Markdown');
      });

  Future<void> _json() => _run(() async {
        final entries = await EntryRepository.instance.allEntries();
        final json = await ExportService.toJson(entries.reversed.toList());
        final file =
            await ExportService.writeTemp('wickly.json', utf8.encode(json));
        await _shareFile(file, 'JSON');
      });

  Future<void> _text() => _run(() async {
        final entries = await EntryRepository.instance.allEntries();
        final file = await ExportService.writeTemp(
          'wickly.txt',
          utf8.encode(ExportService.toPlainText(entries.reversed.toList())),
        );
        await _shareFile(file, tr('export_txt'));
      });

  /// Бэкап просит фразу: без неё его нельзя ни зашифровать, ни поднять.
  Future<String?> _askPassphrase({required bool creating}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(creating ? tr('backup_create') : tr('backup_restore')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              creating ? tr('backup_phrase_hint') : tr('backup_phrase_ask'),
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: tr('backup_phrase')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(tr('done')),
          ),
        ],
      ),
    );
  }

  /// Копия считается устаревшей через две недели — или её нет вовсе.
  static bool _backupStale(DateTime? last) =>
      last == null || DateTime.now().difference(last).inDays >= 14;

  Future<void> _backup() async {
    final phrase = await _askPassphrase(creating: true);
    if (phrase == null || phrase.length < 4) return;
    await _run(() async {
      final bytes = await BackupService.create(
        dbPath: await AppDatabase.instance.filePath,
        passphrase: phrase,
      );
      final stamp = DateTime.now().toIso8601String().substring(0, 10);
      final file = await ExportService.writeTemp(
        'wickly-$stamp.${BackupService.fileExtension}',
        bytes,
      );
      await AppPrefs.instance.markAutoBackup(DateTime.now());
      await _shareFile(file, tr('backup'));
    });
  }

  Future<void> _restore() async {
    final picked = await SystemPause.shield(FilePicker.pickFiles);
    final path = picked?.files.single.path;
    if (path == null || !mounted) return;

    final phrase = await _askPassphrase(creating: false);
    if (phrase == null || phrase.isEmpty) return;

    await _run(() async {
      final mediaKey = await BackupService.restore(
        sealed: await File(path).readAsBytes(),
        passphrase: phrase,
        dbPath: await AppDatabase.instance.filePath,
      );
      // Ключ вложений из бэкапа кладём в системное хранилище: без него
      // фотографии останутся шумом, даже когда база уже на месте.
      if (mediaKey != null && mediaKey.isNotEmpty) {
        await DbKey.replace(mediaKey);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('backup_restored'))),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = AppPrefs.instance;
    final lastBackup = prefs.autoBackupAt;

    return Scaffold(
      appBar: AppBar(title: Text(tr('export_and_backup'))),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 4,
                WicklyDesign.screenPad, 28),
            children: [
              Reveal(child: _BookCard(onTap: _busy ? null : _book)),
              const SizedBox(height: 18),
              SettingsSection(tr('export')),
              SettingsGroup([
                SettingsRow(
                  icon: Icons.description_rounded,
                  title: 'Markdown',
                  subtitle: tr('export_md_sub'),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: _busy ? null : _markdown,
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.data_object_rounded,
                  title: 'JSON',
                  subtitle: tr('export_json_sub'),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: _busy ? null : _json,
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.notes_rounded,
                  title: tr('export_txt'),
                  subtitle: tr('export_txt_sub'),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: _busy ? null : _text,
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.print_rounded,
                  title: tr('print'),
                  subtitle: tr('print_sub'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _busy ? null : _print,
                ),
              ]),
              const SizedBox(height: 18),
              SettingsSection(tr('backup')),
              // Напоминание, а не автоматика: бэкап шифруется фразой, которую
              // знает только человек. Хранить её ради «авто» — значит выдать
              // ключ вместе с замком.
              if (prefs.autoBackup && _backupStale(lastBackup))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _StaleBackupBanner(last: lastBackup),
                ),
              SettingsGroup([
                SettingsRow(
                  icon: Icons.event_repeat_rounded,
                  title: tr('backup_remind'),
                  subtitle: tr('backup_remind_sub'),
                  trailing: Switch(
                    value: prefs.autoBackup,
                    onChanged: (v) async {
                      await prefs.setAutoBackup(v);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.shield_rounded,
                  title: tr('backup_create'),
                  subtitle: lastBackup == null
                      ? tr('backup_none_yet')
                      : trf('backup_last',
                          {'when': Dates.relativeDay(lastBackup)}),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  onTap: _busy ? null : _backup,
                ),
                const SettingsDivider(),
                SettingsRow(
                  icon: Icons.settings_backup_restore_rounded,
                  title: tr('backup_restore'),
                  subtitle: tr('backup_restore_sub'),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  onTap: _busy ? null : _restore,
                ),
              ]),
              const SizedBox(height: 16),
              Text(
                tr('backup_note'),
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 12,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: scheme.surface.withValues(alpha: 0.6),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

/// Карточка «Книга в PDF» — главное действие экрана.
class _BookCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _BookCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      child: Container(
        padding: const EdgeInsets.all(WicklyDesign.gapInside),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 76,
              decoration: BoxDecoration(
                gradient: CoverPalette.gradient('terracotta'),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('pdf_book'),
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.3,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('pdf_book_sub'),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      height: 1.35,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      backgroundColor: scheme.onTertiaryContainer,
                      foregroundColor: scheme.tertiaryContainer,
                    ),
                    onPressed: onTap,
                    child: Text(tr('pdf_book_action')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Напоминание, что резервной копии давно не было.
class _StaleBackupBanner extends StatelessWidget {
  final DateTime? last;

  const _StaleBackupBanner({this.last});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = last == null ? null : DateTime.now().difference(last!).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 20, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              days == null
                  ? tr('backup_none_yet')
                  : trf('backup_stale', {'n': days}),
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: scheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
