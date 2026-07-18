import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'color_picker_sheet.dart';
import 'seed_swatch.dart';

/// Карточка «Оформление»: сегментный переключатель режима темы, тумблеры
/// AMOLED и Material You, палитра акцентов кружками-превью и насыщенность
/// схемы.
///
/// Пришла на смену списку строк с листом выбора: все четыре режима видны
/// сразу, а кружок показывает не одну точку, а четыре тона будущей схемы —
/// по нему видно, во что превратится тема, ещё до нажатия.
class AppearanceCard extends StatelessWidget {
  /// Пресеты акцента. Первый — фирменный [AppTheme.defaultSeed].
  final List<Color> presets;

  const AppearanceCard({super.key, required this.presets});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: ThemeController.instance,
        builder: (context, _) => _card(context),
      );

  Widget _card(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = ThemeController.instance;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AppThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: AppThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded)),
                ButtonSegment(
                    value: AppThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded)),
                ButtonSegment(
                    value: AppThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded)),
                ButtonSegment(
                    value: AppThemeMode.autoTime,
                    icon: Icon(Icons.schedule_rounded)),
              ],
              selected: {theme.mode},
              onSelectionChanged: (s) {
                HapticFeedback.selectionClick();
                theme.setMode(s.first);
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _modeLabel(theme.mode),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),

          // AMOLED имеет смысл только там, где есть тёмный фон.
          if (theme.mode != AppThemeMode.light)
            _Toggle(
              icon: Icons.contrast_rounded,
              title: tr('amoled'),
              subtitle: tr('amoled_sub'),
              value: theme.amoled,
              onChanged: theme.setAmoled,
            ),
          _Toggle(
            icon: Icons.auto_awesome_rounded,
            title: tr('material_you'),
            subtitle: tr('material_you_sub'),
            value: theme.useDynamicColor,
            onChanged: theme.setUseDynamicColor,
          ),

          // Акцент прячем в Material You — там цвет приходит из обоев.
          if (!theme.useDynamicColor) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in presets)
                  SeedSwatch(
                    seed: c,
                    vibrant: theme.vibrantScheme,
                    selected: theme.seedColor.toARGB32() == c.toARGB32(),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      theme.setSeedColor(c);
                    },
                  ),
                _customColorButton(context, scheme, theme),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              tr('theme_intensity'),
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(tr('theme_vibrant')),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                    label: Text(tr('theme_faithful')),
                  ),
                ],
                selected: {theme.vibrantScheme},
                onSelectionChanged: (s) {
                  HapticFeedback.selectionClick();
                  theme.setVibrantScheme(s.first);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _modeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.light => tr('theme_light'),
        AppThemeMode.dark => tr('theme_dark'),
        AppThemeMode.system => tr('theme_system'),
        AppThemeMode.autoTime => tr('theme_auto'),
      };

  /// Кружок «свой цвет». Обведён, когда выбранный цвет не из пресетов —
  /// иначе непонятно, откуда взялся текущий акцент.
  Widget _customColorButton(
      BuildContext context, ColorScheme scheme, ThemeController theme) {
    final custom =
        !presets.any((c) => c.toARGB32() == theme.seedColor.toARGB32());
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked = await showColorPickerSheet(
          context,
          initial: theme.seedColor,
          title: tr('theme_color'),
          resetTo: AppTheme.defaultSeed,
        );
        if (picked != null) await theme.setSeedColor(picked);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.surfaceContainerHighest,
          border: Border.all(
            color: custom ? scheme.onSurface : scheme.outlineVariant,
            width: custom ? 3 : 1,
          ),
        ),
        child: Icon(Icons.colorize_rounded,
            size: 20, color: custom ? theme.seedColor : scheme.onSurfaceVariant),
      ),
    );
  }
}

/// Компактная строка-тумблер внутри карточки оформления.
class _Toggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 11.5,
                      height: 1.3,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
