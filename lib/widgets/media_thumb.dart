import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/media_store.dart';
import '../models/media.dart';
import '../theme/wickly_design.dart';

/// Превью вложения: расшифровывает файл и показывает картинку.
///
/// Файлы лежат зашифрованными, поэтому картинку нельзя отдать обычному
/// `Image.file` — сперва расшифровка в память. Пока байты едут (и если файла
/// нет), рисуем тёплый градиент обложки: экран не должен мигать пустотой.
class MediaThumb extends StatefulWidget {
  final Media? media;

  /// Ключ градиента-заглушки. Обычно `CoverPalette.forSeed(entry.id)`.
  final String? coverKey;

  final BoxFit fit;

  /// Значок поверх превью: «плёнка» у видео, «волна» у аудио.
  final bool showKindBadge;

  const MediaThumb({
    super.key,
    this.media,
    this.coverKey,
    this.fit = BoxFit.cover,
    this.showKindBadge = true,
  });

  @override
  State<MediaThumb> createState() => _MediaThumbState();
}

class _MediaThumbState extends State<MediaThumb> {
  Uint8List? _bytes;

  /// Файл не открылся: показываем это честно, а не тёплым градиентом.
  bool _broken = false;

  /// Видео без кадра-превью: не ошибка, просто нечего показать.
  bool _noPreview = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MediaThumb old) {
    super.didUpdateWidget(old);
    if (old.media?.id != widget.media?.id) _load();
  }

  Future<void> _load() async {
    final m = widget.media;
    if (m == null || m.kind == MediaKind.audio) return;
    // Видео без готового кадра не отдаём в декодер картинок: раньше туда
    // уезжал сам mp4, декодер давился и в сетке висела «сломанная картинка».
    // Лучше честная тёмная плашка со значком воспроизведения.
    if (m.kind == MediaKind.video && m.thumb == null) {
      if (mounted) setState(() => _noPreview = true);
      return;
    }
    // У видео показываем превью-кадр, у фото — само фото. Превью может не
    // получиться (мелкий снимок, незнакомый формат) — тогда берём оригинал.
    var bytes = await MediaStore.instance.read(m.thumb ?? m.file);
    bytes ??= m.thumb == null ? null : await MediaStore.instance.read(m.file);
    if (!mounted) return;
    setState(() {
      _bytes = bytes;
      _broken = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = widget.media;

    Widget layer;
    if (_bytes != null) {
      layer = Image.memory(_bytes!, fit: widget.fit, gaplessPlayback: true);
    } else if (m?.kind == MediaKind.audio) {
      layer = Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.graphic_eq_rounded,
            color: scheme.onSurfaceVariant, size: 26),
      );
    } else if (_noPreview) {
      // Кадр не из чего взять — показываем спокойную плашку, а не ошибку:
      // само видео целое, отсутствует только картинка-превью.
      layer = Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.movie_rounded,
            color: scheme.onSurfaceVariant, size: 26),
      );
    } else if (_broken) {
      layer = Container(
        color: scheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image_rounded,
            color: scheme.onSurfaceVariant, size: 26),
      );
    } else {
      // Пока байты едут — тёплая заглушка обложки.
      layer = DecoratedBox(
        decoration: BoxDecoration(
          gradient: CoverPalette.gradient(widget.coverKey),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        layer,
        if (widget.showKindBadge && m?.kind == MediaKind.video)
          const Center(child: _PlayBadge()),
      ],
    );
  }
}

/// Кружок «плей» поверх превью видео.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
    );
  }
}
