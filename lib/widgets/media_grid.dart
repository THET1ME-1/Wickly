import 'package:flutter/material.dart';

import '../models/media.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import 'media_thumb.dart';
import 'pressable.dart';

/// Сетка вложений внутри текста записи.
///
/// Раскладка зависит от числа фотографий, а не подгоняется под одну сетку:
/// одна занимает всю ширину в своих пропорциях, две делят её пополам, три
/// становятся «крупная плюс две», четыре — квадратом. Дальше четвёртая плитка
/// показывает «+N» и открывает всю пачку.
class MediaGrid extends StatelessWidget {
  final List<Media> media;

  /// Открыть просмотр с указанной позиции.
  final void Function(int index)? onOpen;

  /// Убрать вложение (в редакторе).
  final void Function(Media media)? onRemove;

  /// Сколько плиток показываем, прежде чем свернуть остальное в «+N».
  final int maxVisible;

  const MediaGrid({
    super.key,
    required this.media,
    this.onOpen,
    this.onRemove,
    this.maxVisible = 4,
  });

  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, c) {
      final width = c.maxWidth;
      return switch (media.length) {
        1 => _single(width),
        2 => _two(width),
        3 => _three(width),
        _ => _four(width),
      };
    });
  }

  /// Одна фотография держит свои пропорции: обрезать единственный кадр в
  /// квадрат — потерять именно то, ради чего его сняли.
  Widget _single(double width) {
    final m = media.first;
    final ratio = (m.width != null && m.height != null && m.height! > 0)
        ? m.width! / m.height!
        : 4 / 3;
    // Очень длинные кадры подрезаем: панорама на весь экран ломает чтение.
    final height = (width / ratio.clamp(0.6, 2.2));
    return _tile(m, 0, width: width, height: height);
  }

  Widget _two(double width) {
    final side = (width - _gap) / 2;
    return Row(
      children: [
        _tile(media[0], 0, width: side, height: side),
        const SizedBox(width: _gap),
        _tile(media[1], 1, width: side, height: side),
      ],
    );
  }

  Widget _three(double width) {
    // Три колонки — это два зазора: крупная плитка занимает две из них вместе
    // с зазором между ними.
    final small = (width - _gap * 2) / 3;
    final big = small * 2 + _gap;
    return Row(
      children: [
        _tile(media[0], 0, width: big, height: big),
        const SizedBox(width: _gap),
        Column(
          children: [
            _tile(media[1], 1, width: small, height: small),
            const SizedBox(height: _gap),
            _tile(media[2], 2, width: small, height: small),
          ],
        ),
      ],
    );
  }

  Widget _four(double width) {
    final side = (width - _gap) / 2;
    final hidden = media.length - maxVisible;
    return Column(
      children: [
        Row(
          children: [
            _tile(media[0], 0, width: side, height: side),
            const SizedBox(width: _gap),
            _tile(media[1], 1, width: side, height: side),
          ],
        ),
        const SizedBox(height: _gap),
        Row(
          children: [
            _tile(media[2], 2, width: side, height: side),
            const SizedBox(width: _gap),
            _tile(
              media[3],
              3,
              width: side,
              height: side,
              more: hidden > 0 ? hidden : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _tile(
    Media m,
    int index, {
    required double width,
    required double height,
    int? more,
  }) =>
      _GridTile(
        media: m,
        width: width,
        height: height,
        more: more,
        onTap: onOpen == null ? null : () => onOpen!(index),
        onRemove: onRemove == null ? null : () => onRemove!(m),
      );
}

class _GridTile extends StatelessWidget {
  final Media media;
  final double width;
  final double height;
  final int? more;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _GridTile({
    required this.media,
    required this.width,
    required this.height,
    this.more,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PressableScale(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WicklyDesign.radiusCover),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaThumb(media: media, coverKey: CoverPalette.forSeed(media.id)),
                if (more != null)
                  Container(
                    color: const Color(0x99000000),
                    alignment: Alignment.center,
                    child: Text(
                      '+$more',
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (onRemove != null)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: scheme.onSurface),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
