import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Reveal(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(44),
                ),
                child: Icon(icon, size: 68, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 28),
            Reveal(
              delay: const Duration(milliseconds: 80),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
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
    );
  }
}
