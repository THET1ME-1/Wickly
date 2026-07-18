import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/app_prefs.dart';
import '../data/db.dart';
import '../l10n/strings.dart';
import '../services/p2p_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';
import '../widgets/settings_scaffold.dart';

/// Как синхронизируемся.
enum SyncMode { direct, folder }

/// Синхронизация между своими устройствами.
///
/// Два пути и оба без сервера: прямой обмен по домашней сети (QR или фраза) и
/// общая папка, которую доставляет Syncthing. Наружу уходят только пакеты
/// изменений — файл базы не пересылается никогда.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  SyncMode _mode = SyncMode.direct;

  P2pHost? _host;
  String _phrase = '';
  String? _status;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _phrase = SyncService.generatePhrase();
  }

  @override
  void dispose() {
    _host?.close();
    super.dispose();
  }

  /// Поднимает приём и ждёт второе устройство.
  Future<void> _startHosting() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = tr('sync_waiting');
    });
    try {
      final host = await P2pService.host(phrase: _phrase);
      setState(() => _host = host);
      final report = await host.exchange();
      if (!mounted) return;
      setState(() => _status = trf('sync_done', {'n': report.rows}));
    } catch (e) {
      if (mounted) setState(() => _status = tr('sync_failed'));
    } finally {
      await _host?.close();
      if (mounted) {
        setState(() {
          _host = null;
          _busy = false;
        });
      }
    }
  }

  /// Кладёт пакет в общую папку и подхватывает чужие.
  Future<void> _syncFolder() async {
    if (_busy) return;
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return;

    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final key = await SyncService.keyFromPhrase(_phrase);
      final folder = Directory(path);

      var merged = 0;
      for (final file in SyncFolder.foreignPackets(folder, Db.crdt.nodeId)) {
        final packet =
            await SyncService.openPacket(await file.readAsBytes(), key);
        merged += (await SyncService.applyPacket(packet)).rows;
      }

      final sealed = await SyncService.sealPacket(
          await SyncService.buildPacket(), key);
      await SyncFolder.writePacket(folder, sealed, Db.crdt.nodeId);

      if (mounted) {
        setState(() => _status = trf('sync_done', {'n': merged}));
      }
    } catch (_) {
      if (mounted) setState(() => _status = tr('sync_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr('sync'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 4,
            WicklyDesign.screenPad, 28),
        children: [
          _ModeTabs(
            mode: _mode,
            onChange: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: 16),

          Reveal(
            child: _StatusCard(
              status: _status,
              busy: _busy,
              lastSync: AppPrefs.instance.autoBackupAt,
            ),
          ),
          const SizedBox(height: 16),

          if (_mode == SyncMode.direct) ...[
            Reveal(
              delay: const Duration(milliseconds: 60),
              child: _PairCard(
                invite: _host?.invite,
                phrase: _phrase,
                busy: _busy,
                onStart: _startHosting,
                onNewPhrase: () =>
                    setState(() => _phrase = SyncService.generatePhrase()),
              ),
            ),
            const SizedBox(height: 12),
            SettingsGroup([
              SettingsRow(
                icon: Icons.qr_code_scanner_rounded,
                title: tr('sync_scan'),
                subtitle: tr('sync_scan_sub'),
                trailing:
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
                onTap: () => Navigator.of(context).pushNamed('/sync/scan'),
              ),
            ]),
          ] else
            Reveal(
              delay: const Duration(milliseconds: 60),
              child: SettingsGroup([
                SettingsRow(
                  icon: Icons.folder_shared_rounded,
                  title: tr('sync_folder'),
                  subtitle: tr('sync_folder_sub'),
                  trailing:
                      Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  onTap: _syncFolder,
                ),
              ]),
            ),

          const SizedBox(height: 18),
          Text(
            tr('sync_note'),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final SyncMode mode;
  final ValueChanged<SyncMode> onChange;

  const _ModeTabs({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          for (final m in SyncMode.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: AppTheme.emphasized,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode == m
                        ? scheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    m == SyncMode.direct
                        ? tr('sync_mode_direct')
                        : tr('sync_mode_folder'),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mode == m
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Состояние синхронизации: что произошло в последний раз.
class _StatusCard extends StatelessWidget {
  final String? status;
  final bool busy;
  final DateTime? lastSync;

  const _StatusCard({
    required this.status,
    required this.busy,
    this.lastSync,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(WicklyDesign.gapInside),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
      ),
      child: Row(
        children: [
          if (busy)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: scheme.onTertiaryContainer,
              ),
            )
          else
            Icon(Icons.check_circle_rounded,
                color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status ?? tr('sync_ready'),
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: scheme.onTertiaryContainer,
                  ),
                ),
                if (lastSync != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    Dates.relativeDay(lastSync!),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 12.5,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка сопряжения: QR, фраза и кнопка «ждать устройство».
class _PairCard extends StatelessWidget {
  final PairInvite? invite;
  final String phrase;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onNewPhrase;

  const _PairCard({
    required this.invite,
    required this.phrase,
    required this.busy,
    required this.onStart,
    required this.onNewPhrase,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(WicklyDesign.gapInside),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
      ),
      child: Column(
        children: [
          Text(
            tr('sync_add_device'),
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          // QR появляется только когда приём поднят: иначе он вёл бы на порт,
          // который никто не слушает.
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: invite == null
                ? Icon(Icons.qr_code_2_rounded,
                    size: 90, color: Colors.black.withValues(alpha: 0.18))
                : QrImageView(
                    data: invite!.encode(),
                    size: 170,
                    backgroundColor: Colors.white,
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            tr('sync_or_phrase'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          PressableScale(
            child: GestureDetector(
              onTap: busy ? null : onNewPhrase,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  phrase,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: busy ? null : onStart,
              child: Text(busy ? tr('sync_waiting') : tr('sync_start')),
            ),
          ),
        ],
      ),
    );
  }
}
