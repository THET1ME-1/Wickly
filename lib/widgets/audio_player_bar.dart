import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../data/media_store.dart';
import '../models/media.dart';
import '../theme/app_theme.dart';

/// Проигрыватель аудио-заметки внутри записи.
///
/// Файл лежит зашифрованным, поэтому перед игрой его расшифрованная копия
/// кладётся во временный каталог — плееру нужен настоящий путь. Копии стираются
/// при блокировке дневника (см. [MediaStore.clearTemp]).
class AudioPlayerBar extends StatefulWidget {
  final Media media;

  const AudioPlayerBar({super.key, required this.media});

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  AudioPlayer? _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    final ms = widget.media.durationMs;
    if (ms != null) _total = Duration(milliseconds: ms);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final player = _player ??= _createPlayer();
    if (_playing) {
      await player.pause();
      setState(() => _playing = false);
      return;
    }
    final path = await MediaStore.instance.materialize(widget.media.file);
    if (path == null) return;
    await player.play(DeviceFileSource(path));
    if (mounted) setState(() => _playing = true);
  }

  AudioPlayer _createPlayer() {
    final player = AudioPlayer();
    player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
    player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
    return player;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Material(
            color: scheme.primaryContainer,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _toggle,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _format(_playing || _position > Duration.zero ? _position : _total),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }
}
