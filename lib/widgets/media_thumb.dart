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
    // У видео показываем превью-кадр, у фото — само фото.
    final name = m.thumb ?? m.file;
    final bytes = await MediaStore.instance.read(name);
    if (mounted) setState(() => _bytes = bytes);
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
    } else {
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
