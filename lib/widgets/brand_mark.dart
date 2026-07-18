import 'package:flutter/material.dart';

/// Знак Wickly: скруглённый квадрат с тёплым градиентом и пером.
///
/// Перо — метафора дневника, тёплый градиент — «свет лампы» (wick, фитиль).
/// Градиент строится из акцента текущей темы, поэтому знак живёт вместе с
/// выбранным цветом, а не спорит с ним.
class BrandMark extends StatelessWidget {
  final double size;

  /// Тень под знаком — на титульных экранах она уместна, в списке лишняя.
  final bool glow;

  const BrandMark({super.key, this.size = 76, this.glow = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = size * 0.28;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(scheme.primary, scheme.tertiary, 0.25)!,
            scheme.primary,
          ],
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: size * 0.55,
                  spreadRadius: -size * 0.06,
                  offset: Offset(0, size * 0.16),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.edit_note_rounded,
        size: size * 0.52,
        color: scheme.onPrimary,
      ),
    );
  }
}
