import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import 'reveal.dart';

/// Крупная выразительная «заглушка» для пустых/будущих разделов в духе
/// Material 3 Expressive: большая скруглённая плашка с иконкой, заголовок и
/// подпись. Появляется с каскадной анимацией.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // На широком окне вокруг заглушки много воздуха, и телефонный знак
    // в 140 точек посреди монитора выглядит потерянным, а не спокойным.
    final wide = WicklyDesign.isWide(context);
    final mark = wide ? 104.0 : 140.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          // Подпись в одну длинную строку на весь монитор не читается.
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Reveal(
              child: Container(
                width: mark,
                height: mark,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(mark * 0.31),
                ),
                child: Icon(icon,
                    size: mark * 0.49, color: scheme.onPrimaryContainer),
              ),
            ),
            SizedBox(height: wide ? 22 : 28),
            Reveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: wide ? 23 : 26,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Reveal(
              delay: const Duration(milliseconds: 140),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 15,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              Reveal(delay: const Duration(milliseconds: 200), child: action!),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
