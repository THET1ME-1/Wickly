import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../widgets/brand_mark.dart';
import '../widgets/reveal.dart';

/// Первый экран: обещание приватности и вход в один тап.
///
/// Регистрации нет, поэтому экран ничего не спрашивает — он только объясняет,
/// на что человек соглашается, и уводит внутрь. Второй путь — поднять дневник
/// из бэкапа, если человек переезжает с другого телефона.
class OnboardingScreen extends StatelessWidget {
  /// Завести дневник и войти.
  final VoidCallback onStart;

  /// Поднять дневник из файла бэкапа.
  final VoidCallback onRestore;

  const OnboardingScreen({
    super.key,
    required this.onStart,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Reveal(child: Center(child: BrandMark(size: 82))),
                  const SizedBox(height: 22),
                  Reveal(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      'Wickly',
                      textAlign: TextAlign.center,
                      style: text.displaySmall?.copyWith(
                        color: scheme.onSurface,
                        fontSize: 44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Reveal(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      tr('onb_tagline'),
                      textAlign: TextAlign.center,
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Три обещания. Цвета плашек берём из ролей схемы, поэтому
                  // они переживают и смену акцента, и Material You.
                  _Promise(
                    icon: Icons.lock_rounded,
                    background: scheme.primaryContainer,
                    foreground: scheme.onPrimaryContainer,
                    title: tr('onb_f1_title'),
                    subtitle: tr('onb_f1_sub'),
                    delay: const Duration(milliseconds: 180),
                  ),
                  _Promise(
                    icon: Icons.shield_rounded,
                    background: scheme.tertiaryContainer,
                    foreground: scheme.onTertiaryContainer,
                    title: tr('onb_f2_title'),
                    subtitle: tr('onb_f2_sub'),
                    delay: const Duration(milliseconds: 240),
                  ),
                  _Promise(
                    icon: Icons.sync_rounded,
                    background: scheme.secondaryContainer,
                    foreground: scheme.onSecondaryContainer,
                    title: tr('onb_f3_title'),
                    subtitle: tr('onb_f3_sub'),
                    delay: const Duration(milliseconds: 300),
                  ),

                  const SizedBox(height: 30),
                  Reveal(
                    delay: const Duration(milliseconds: 360),
                    child: FilledButton(
                      onPressed: onStart,
                      child: Text(tr('onb_cta')),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Reveal(
                    delay: const Duration(milliseconds: 400),
                    child: TextButton.icon(
                      onPressed: onRestore,
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(tr('onb_restore')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Одно обещание приватности: цветная плашка-иконка, заголовок и пояснение.
class _Promise extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;
  final Duration delay;

  const _Promise({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Reveal(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: foreground, size: 23),
            ),
            const SizedBox(width: WicklyDesign.gapInside),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13.5,
                      height: 1.35,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
