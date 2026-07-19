import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';

/// Открывает экран так, как принято на этой ширине окна: на телефоне —
/// страницей во весь экран, на десктопе — плавающей панелью поверх ленты.
///
/// Полноэкранный переход на мониторе выглядит телефонным: лента исчезает
/// целиком ради одной записи, и человек теряет место, где стоял. Панель
/// оставляет сетку на виду и закрывается по Esc, по клику мимо и кнопкой.
Route<T> pageOrPanel<T>(
  BuildContext context,
  WidgetBuilder builder, {
  double maxWidth = 980,
}) =>
    WicklyDesign.isWide(context)
        ? PanelRoute<T>(builder: builder, maxWidth: maxWidth)
        : MaterialPageRoute<T>(builder: builder);

/// Плавающая панель поверх экрана.
class PanelRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;
  final double maxWidth;

  /// Панель по высоте содержимого (лист выбора) вместо панели во весь рост
  /// (запись). Нижний лист на мониторе выезжает откуда-то из-под стола —
  /// на этой ширине он становится окном по центру.
  final bool fitContent;

  PanelRoute({
    required this.builder,
    this.maxWidth = 980,
    this.fitContent = false,
  });

  @override
  Color? get barrierColor => const Color(0x80000000);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => MaterialLocalizations
      .of(navigator!.context)
      .modalBarrierDismissLabel;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 240);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 180);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final size = MediaQuery.sizeOf(context);
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: size.height > 760 ? 48 : 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: fitContent ? size.height * 0.86 : 900,
          ),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                if (isCurrent) Navigator.of(context).maybePop();
              },
            },
            child: FocusScope(
              autofocus: true,
              child: Material(
                color: scheme.surfaceContainer,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(WicklyDesign.radiusCard),
                ),
                // По высоте содержимого — только если сам экран этого просит:
                // `Column(mainAxisSize.min)` внутри листа тогда решает сам.
                child: fitContent
                    ? IntrinsicHeight(child: Builder(builder: _scoped))
                    : Builder(builder: _scoped),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoped(BuildContext context) =>
      _PanelScope(child: Builder(builder: builder));

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppTheme.emphasizedDecelerate,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: curved,
      // Панель приезжает от центра, а не сбоку: она не «следующий экран», а
      // слой поверх того же места.
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

/// Метка «этот экран открыт панелью» — по ней экраны меняют кнопку «назад» на
/// «закрыть» и убирают лишние поля.
class _PanelScope extends InheritedWidget {
  const _PanelScope({required super.child});

  @override
  bool updateShouldNotify(_PanelScope oldWidget) => false;
}

/// Открыт ли текущий экран плавающей панелью.
bool inPanel(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_PanelScope>() != null;
