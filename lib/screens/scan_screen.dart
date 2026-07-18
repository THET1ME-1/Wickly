import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/strings.dart';
import '../services/p2p_service.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';

/// Сканер QR для сопряжения устройств.
///
/// Вторая половина синхронизации: одно устройство показывает код, это — читает
/// и сразу делает обмен. Ручной ввод фразы оставлен рядом, потому что камера
/// есть не всегда и не у всех она разрешена.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;
    final invite = PairInvite.decode(raw);
    if (invite == null) return;

    _handled = true;
    await _controller.stop();
    await _connect(invite);
  }

  Future<void> _connect(PairInvite invite) async {
    setState(() => _status = tr('sync_waiting'));
    try {
      final report = await P2pService.connect(invite);
      if (!mounted) return;
      setState(() => _status = trf('sync_done', {'n': report.rows}));
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = tr('sync_failed');
          _handled = false;
        });
        await _controller.start();
      }
    }
  }

  /// Ввод фразы руками: адрес спрашиваем отдельно, потому что без QR его
  /// неоткуда взять.
  Future<void> _manual() async {
    final host = TextEditingController();
    final phrase = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('sync_manual')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: host,
              decoration: InputDecoration(labelText: tr('sync_address')),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phrase,
              decoration: InputDecoration(labelText: tr('backup_phrase')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('done')),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final parts = host.text.trim().split(':');
    await _connect(PairInvite(
      host: parts.first,
      port: parts.length > 1
          ? (int.tryParse(parts[1]) ?? P2pService.defaultPort)
          : P2pService.defaultPort,
      phrase: phrase.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('sync_scan')),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_rounded),
            tooltip: tr('sync_manual'),
            onPressed: _manual,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Рамка прицела: без неё непонятно, куда наводить.
          Center(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.primary, width: 3),
                borderRadius: BorderRadius.circular(WicklyDesign.radiusCover),
              ),
            ),
          ),
          if (_status != null)
            Positioned(
              left: WicklyDesign.screenPad,
              right: WicklyDesign.screenPad,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.all(WicklyDesign.gapInside),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
                ),
                child: Text(
                  _status!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
