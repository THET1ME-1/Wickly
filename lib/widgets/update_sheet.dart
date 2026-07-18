import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_prefs.dart';
import '../l10n/strings.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

/// Нижнее M3-меню «Доступно обновление»: показывает новую версию и описание,
/// по кнопке «Обновить» скачивает APK с GitHub (с прогрессом) и запускает
/// системный установщик. Если APK в релизе нет или что-то сломалось —
/// предлагает открыть страницу релиза в браузере. (Как в ScoreMaster.)
class UpdateSheet extends StatefulWidget {
  final UpdateInfo info;
  final String currentVersion;

  const UpdateSheet({
    super.key,
    required this.info,
    required this.currentVersion,
  });

  static Future<void> show(
    BuildContext context,
    UpdateInfo info,
    String currentVersion,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => UpdateSheet(info: info, currentVersion: currentVersion),
    );
  }

  @override
  State<UpdateSheet> createState() => _UpdateSheetState();
}

enum _Stage { idle, downloading, installing, failed }

class _UpdateSheetState extends State<UpdateSheet> {
  _Stage _stage = _Stage.idle;
  double _progress = 0;

  /// «Позже» — про эту версию сама больше не напоминает. Ручная проверка в
  /// настройках покажет её снова: там человек спрашивает сам.
  Future<void> _later() async {
    await AppPrefs.instance.setSkippedUpdate(widget.info.version);
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _openGithub() async {
    await launchUrl(Uri.parse(widget.info.releaseUrl),
        mode: LaunchMode.externalApplication);
  }

  Future<void> _startUpdate() async {
    HapticFeedback.mediumImpact();
    final url = widget.info.apkUrl;
    if (url == null) {
      await _openGithub();
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    setState(() {
      _stage = _Stage.downloading;
      _progress = 0;
    });

    final path = await UpdateService.downloadApk(
      url,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;
    if (path == null) {
      setState(() => _stage = _Stage.failed);
      return;
    }

    setState(() => _stage = _Stage.installing);
    final result = await OpenFilex.open(path,
        type: 'application/vnd.android.package-archive');
    if (!mounted) return;
    if (result.type != ResultType.done) {
      setState(() => _stage = _Stage.failed);
    }
    // При успехе появляется системный установщик поверх приложения.
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = widget.info;
    final busy = _stage == _Stage.downloading || _stage == _Stage.installing;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.system_update_rounded,
                      color: scheme.onPrimaryContainer, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('update_available'),
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${trf('update_new_version', {'v': info.version})}  ·  '
                        '${trf('update_current_version', {'v': widget.currentVersion})}',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                tr('update_whats_new'),
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    info.notes,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
            if (_stage == _Stage.downloading) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 10,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                trf('update_downloading', {'p': (_progress * 100).round()}),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else if (_stage == _Stage.installing) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tr('update_installing'),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ] else if (_stage == _Stage.failed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  tr('update_failed'),
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_stage == _Stage.failed) ...[
              FilledButton.icon(
                onPressed: _openGithub,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(tr('update_open_github')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _later,
                child: Text(tr('update_later')),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: busy ? null : _startUpdate,
                icon: const Icon(Icons.download_rounded),
                label: Text(tr('update_now')),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: busy ? null : _openGithub,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(tr('update_open_github')),
              ),
              if (!busy)
                TextButton(
                  onPressed: _later,
                  child: Text(tr('update_later')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
