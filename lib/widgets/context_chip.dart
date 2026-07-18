import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';

/// Пилюля авто-контекста: дата, настроение, погода, место, тег.
///
/// Один вид на всё приложение — карточка ленты, шапка редактора и читалка
/// показывают контекст одинаково, поэтому глаз не переучивается между экранами.
class ContextChip extends StatelessWidget {
  /// Кружок слева (настроение, погода). Взаимоисключим с [icon].
  final Color? dotColor;
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;

  /// Подсвеченная пилюля — выбранное значение.
  final bool selected;

  const ContextChip({
    super.key,
    this.dotColor,
    this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  /// Пилюля настроения: кружок нужной ступени и её название.
  factory ContextChip.mood(BuildContext context, int mood,
          {VoidCallback? onTap}) =>
      ContextChip(
        dotColor: MoodPaletteX.of(context, mood),
        label: MoodPaletteX.label(mood),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background =
        selected ? scheme.primaryContainer : scheme.surfaceContainerHigh;
    final foreground =
        selected ? scheme.onPrimaryContainer : scheme.onSurface;

    // Высота и отступы заданы контейнером, а ширина остаётся по содержимому:
    // иначе Wrap растягивает пилюлю на всю строку.
    final content = Container(
      height: 34,
      padding: EdgeInsets.fromLTRB(
          icon != null || dotColor != null ? 10 : 14, 0, 14, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: background,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}
