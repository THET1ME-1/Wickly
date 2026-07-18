import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Каркас нижнего листа по ДНК: хват, углы 28, фон `surfaceContainer`.
///
/// Один каркас на все листы приложения, чтобы они не расходились по мелочам —
/// высоте хвата, отступам и месту заголовка.
class SheetScaffold extends StatelessWidget {
  final String? title;

  /// Кнопка справа от заголовка (например, «＋»).
  final Widget? action;

  /// Кнопка слева (например, «назад» в многошаговом листе).
  final Widget? leading;

  final Widget child;

  /// Прижатая к низу кнопка действия.
  final Widget? bottom;

  /// Лист во весь экран (менеджер эмоций) вместо высоты по содержимому.
  final bool expand;

  const SheetScaffold({
    super.key,
    this.title,
    this.action,
    this.leading,
    required this.child,
    this.bottom,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                SizedBox(width: 44, child: leading),
                Expanded(
                  child: Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 44, child: action),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (expand) Expanded(child: child) else Flexible(child: child),
        if (bottom != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: bottom,
          ),
        const SizedBox(height: 6),
      ],
    );

    return SafeArea(top: false, child: content);
  }
}

/// Открывает лист с оформлением ДНК: углы 28, фон `surfaceContainer`.
Future<T?> showWicklySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: scheme.surfaceContainer,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => expand
        ? SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: builder(context),
          )
        : builder(context),
  );
}
