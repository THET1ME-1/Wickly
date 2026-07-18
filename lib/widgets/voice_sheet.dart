import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/system_pause.dart';
import '../l10n/locale_controller.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'sheet_scaffold.dart';

/// Что принёс лист голоса: расшифровку речи, аудио-файл или и то, и другое.
class VoiceResult {
  final String? transcript;
  final String? audioPath;
  final int? durationMs;

  const VoiceResult({this.transcript, this.audioPath, this.durationMs});
}

/// Голос в записи: живая расшифровка речи в текст либо аудио-заметка.
///
/// Две вкладки, потому что это разные намерения: «мне лень печатать» и «хочу
/// сохранить свой голос». Расшифровка идёт средствами телефона и наружу ничего
/// не отправляет.
Future<VoiceResult?> showVoiceSheet(
  BuildContext context, {
  required String entryId,
}) =>
    showWicklySheet<VoiceResult>(
      context,
      builder: (_) => const _VoiceSheet(),
    );

/// Тот же лист голоса, но как обычный экран — для снимков в `test_golden`.
/// Нужен потому, что модальный лист в снимок целиком не попадает.
@visibleForTesting
class VoiceSheetPreview extends StatelessWidget {
  const VoiceSheetPreview({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        body: const _VoiceSheet(),
      );
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  bool _dictation = true;

  final _speech = SpeechToText();

  /// Диктофон создаётся при первой записи: его конструктор сразу лезет в
  /// нативный слой, а на вкладке диктовки он вообще не нужен.
  AudioRecorder? _recorderOrNull;
  AudioRecorder get _recorder => _recorderOrNull ??= AudioRecorder();

  bool _speechReady = false;
  bool _running = false;
  String _transcript = '';
  String? _error;

  /// Локаль распознавания в том виде, в каком её знает движок телефона
  /// («ru_RU»), а не голый код языка. Null — пусть берёт системную.
  String? _speechLocale;

  String? _audioPath;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  /// Уровень звука для «волны» — сглаженный, иначе картинка дёргается.
  double _level = 0;
  final _levels = List<double>.filled(28, 0.12);

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _speech.cancel();
    _recorderOrNull?.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      // Первая инициализация просит доступ к микрофону системным окном — оно
      // уводит приложение в фон, а замок такого не отличал от «свернули».
      final ok = await SystemPause.shield(() => _speech.initialize(
        // Ошибка гасит слушание (cancelOnError), поэтому вместе с текстом
        // обязательно снимаем «идёт запись» — иначе кнопка залипает на паузе.
        // Оба колбэка живут, пока открыт лист, и приходят даже когда человек
        // пишет аудио-заметку. Трогаем «идёт запись» только на своей вкладке,
        // иначе распознавание глушит чужой диктофон.
        onError: (e) {
          if (mounted && _dictation) {
            setState(() {
              _error = tr('voice_unavailable');
              _running = false;
            });
          }
        },
        // Движок сам замолкает после паузы в речи. Без этого UI продолжал
        // показывать «Слушаю…» над мёртвым распознаванием.
        onStatus: (status) {
          if (mounted && _dictation && status != 'listening') {
            setState(() => _running = false);
          }
        },
      ));
      if (!mounted) return;
      setState(() => _speechReady = ok);
      if (ok) await _pickSpeechLocale();
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  /// Подбирает локаль распознавания под язык интерфейса.
  ///
  /// Движок знает локали вида «ru_RU»/«ru-RU», а не «ru»: передать голый код
  /// языка — значит не совпасть ни с чем и остаться без распознавания.
  Future<void> _pickSpeechLocale() async {
    try {
      final code = LocaleController.instance.code.toLowerCase();
      final locales = await _speech.locales();
      final match = locales.where((l) {
        final id = l.localeId.toLowerCase().replaceAll('-', '_');
        return id == code || id.startsWith('${code}_');
      });
      if (match.isNotEmpty && mounted) {
        setState(() => _speechLocale = match.first.localeId);
      }
    } catch (_) {
      // Не смогли спросить список — пусть распознаёт на системном языке.
    }
  }

  // ----------------------------- Диктовка -----------------------------

  Future<void> _toggleDictation() async {
    if (_running) {
      await _speech.stop();
      setState(() => _running = false);
      return;
    }
    if (!_speechReady) {
      setState(() => _error = tr('voice_unavailable'));
      return;
    }
    setState(() {
      _error = null;
      _running = true;
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: _speechLocale,
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (r) => setState(() => _transcript = r.recognizedWords),
      onSoundLevelChange: _pushSpeechLevel,
    );
  }

  // -------------------------- Аудио-заметка --------------------------

  Future<void> _toggleRecording() async {
    if (_running) {
      _ticker?.cancel();
      String? path;
      try {
        path = await _recorder.stop();
      } catch (e) {
        path = null;
      }
      // Диктофон дописывает файл уже после stop(), поэтому короткая запись
      // могла уехать в дневник нулевой. Ждём, пока в файле появятся байты.
      final ok = path != null && await _hasSound(path);
      if (!mounted) return;
      setState(() {
        _running = false;
        _audioPath = ok ? path : null;
        // Молчать нельзя: человек говорил в микрофон и вправе знать, что
        // записи нет, а не находить пустоту потом.
        if (!ok) _error = tr('voice_record_failed');
      });
      return;
    }

    // Диктофон живёт в нативном слое, и промахнуться может каждый шаг:
    // разрешение, кодек, занятый другим приложением микрофон. Раньше любой
    // из них рушил обработчик молча, и кнопка просто ничего не делала.
    try {
      // Тоже открывает системное окно на первом разе.
      if (!await SystemPause.shield(() => _recorder.hasPermission())) {
        if (mounted) setState(() => _error = tr('mic_denied'));
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/wickly_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // Параметры задаём явно: значения по умолчанию у разных прошивок
      // разные, и на части устройств запись уходит в пустой файл.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;

      _elapsed = Duration.zero;
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) async {
        try {
          final amp = await _recorder.getAmplitude();
          // Амплитуда приходит в дБ (около −45…0) — приводим к 0..1.
          _pushLevel(((amp.current + 45) / 45).clamp(0.05, 1).toDouble());
        } catch (_) {
          // Уровень — украшение. Не отдал, и ладно: запись важнее волны.
        }
        if (mounted) {
          setState(() => _elapsed += const Duration(milliseconds: 200));
        }
      });
      setState(() {
        _error = null;
        _running = true;
        _audioPath = null;
      });
    } catch (e) {
      _ticker?.cancel();
      if (mounted) {
        setState(() {
          _running = false;
          _error = '${tr('voice_record_failed')}\n$e';
        });
      }
    }
  }

  /// Дожидается, пока диктофон допишет файл, и проверяет, что он не пустой.
  Future<bool> _hasSound(String path) async {
    final file = File(path);
    for (var i = 0; i < 20; i++) {
      if (file.existsSync() && await file.length() > 1024) return true;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return false;
  }

  /// Уровень распознавания приходит примерно в −2…10 — приводим к 0..1.
  void _pushSpeechLevel(double raw) =>
      _pushLevel(((raw + 2) / 12).clamp(0.05, 1).toDouble());

  /// Принимает готовый 0..1. Раньше сюда шли обе шкалы разом, и уровень
  /// диктофона нормировался дважды: волна прижималась к минимуму и стояла
  /// ровным частоколом независимо от голоса.
  void _pushLevel(double norm) {
    _level = _level * 0.6 + norm * 0.4;
    _levels
      ..removeAt(0)
      ..add(_level);
    if (mounted) setState(() {});
  }

  void _accept() {
    Navigator.of(context).pop(VoiceResult(
      transcript: _dictation && _transcript.trim().isNotEmpty
          ? _transcript.trim()
          : null,
      audioPath: _dictation ? null : _audioPath,
      durationMs: _dictation ? null : _elapsed.inMilliseconds,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canAccept = _dictation
        ? _transcript.trim().isNotEmpty
        : (_audioPath != null && !_running);

    return SheetScaffold(
      title: tr('voice'),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      action: IconButton(
        icon: const Icon(Icons.check_rounded),
        onPressed: canAccept ? _accept : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Tabs(
              dictation: _dictation,
              onChange: _running
                  ? null
                  : (v) => setState(() {
                        _dictation = v;
                        _error = null;
                      }),
            ),
            const SizedBox(height: 26),
            Text(
              _dictation
                  ? (_running ? tr('voice_listening') : tr('voice_tap_to_start'))
                  : _format(_elapsed),
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: _dictation ? 20 : 40,
                letterSpacing: -0.5,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: CustomPaint(
                size: const Size(double.infinity, 54),
                painter: _WavePainter(
                  levels: _levels,
                  color: scheme.primary,
                  active: _running,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: scheme.error,
                  ),
                ),
              ),
            if (_dictation && _transcript.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          tr('voice_transcript'),
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _transcript,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 14,
                        height: 1.4,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            _RecordButton(
              running: _running,
              onTap: _dictation ? _toggleDictation : _toggleRecording,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }
}

/// Переключатель «Диктовка ↔ Аудио-заметка».
class _Tabs extends StatelessWidget {
  final bool dictation;
  final ValueChanged<bool>? onChange;

  const _Tabs({required this.dictation, this.onChange});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tab(String label, bool value) => Expanded(
          child: GestureDetector(
            onTap: onChange == null ? null : () => onChange!(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: AppTheme.emphasized,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dictation == value
                    ? scheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dictation == value
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          tab(tr('voice_dictation'), true),
          tab(tr('voice_note'), false),
        ],
      ),
    );
  }
}

/// Круглая кнопка записи: пуск и пауза.
class _RecordButton extends StatelessWidget {
  final bool running;
  final VoidCallback onTap;

  const _RecordButton({required this.running, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: AppTheme.emphasized,
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: running ? scheme.errorContainer : scheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          running ? Icons.pause_rounded : Icons.mic_rounded,
          size: 34,
          color: running ? scheme.onErrorContainer : scheme.onPrimary,
        ),
      ),
    );
  }
}

/// Столбики уровня звука.
class _WavePainter extends CustomPainter {
  final List<double> levels;
  final Color color;
  final bool active;

  const _WavePainter({
    required this.levels,
    required this.color,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: active ? 1 : 0.35)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    final step = size.width / levels.length;
    for (var i = 0; i < levels.length; i++) {
      final x = step * i + step / 2;
      // Даже в тишине оставляем короткую засечку — линия читается как шкала.
      final h = math.max(4.0, levels[i] * size.height);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.levels != levels || old.active != active || old.color != color;
}
