import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'color_picker_sheet.dart';
import 'settings_scaffold.dart';

/// Подписи блока «Оформление». По умолчанию — русские. Переопредели под свою
/// локализацию (передай значения из своего `tr(...)`).
class AppearanceLabels {
  final String section; // заголовок секции
  final String themeMode; // строка «Тема»
  final String themeModeSheetTitle; // заголовок листа выбора темы
  final String light;
  final String dark;
  final String system;
  final String autoTime;
  final String amoled;
  final String amoledSub;
  final String dynamicColor; // «Material You»
  final String dynamicColorSub;
  final String themeColor; // «Цвет оформления»
  final String themeColorDefault; // подпись, когда цвет стандартный
  final String presets; // подпись ряда палитр

  const AppearanceLabels({
    this.section = 'Оформление',
    this.themeMode = 'Тема',
    this.themeModeSheetTitle = 'Тема оформления',
    this.light = 'Светлая',
    this.dark = 'Тёмная',
    this.system = 'Как в системе',
    this.autoTime = 'По времени суток',
    this.amoled = 'AMOLED',
    this.amoledSub = 'Чистый чёрный фон в тёмной теме',
    this.dynamicColor = 'Material You',
    this.dynamicColorSub = 'Цвет из обоев системы (Android 12+)',
    this.themeColor = 'Цвет оформления',
    this.themeColorDefault = 'Стандартный',
    this.presets = 'Палитры',
  });
}

/// Палитра пресетов цвета оформления по умолчанию. Первый — фирменный
/// `AppTheme.defaultSeed`. Переопредели список под приложение при желании.
const List<Color> kDefaultThemePresets = [
  AppTheme.defaultSeed,
  Color(0xFF1E88E5), // синий
  Color(0xFF7E57C2), // фиолетовый
  Color(0xFF43A047), // зелёный
  Color(0xFFFB8C00), // оранжевый
  Color(0xFFE53935), // красный
  Color(0xFFEC407A), // розовый
  Color(0xFF00897B), // изумрудный
];

/// Готовый блок «Оформление» для экрана настроек — эталон ScoreMaster.
///
/// Рендерит заголовок секции и карточку-группу с общими для всех наших
/// приложений пунктами: выбор темы (4 режима), AMOLED (в тёмной теме),
/// Material You и свой цвет + палитры. Всё завязано на
/// [ThemeController.instance] и обновляется на лету.
///
/// Специфичные для приложения пункты (звук, язык, размер текста, …) добавь
/// через [extraRows] — они приклеятся в ту же карточку, каждый после
/// разделителя, сохраняя единый вид.
///
/// ```dart
/// AppearanceSettings(
///   presets: kDefaultThemePresets,
///   extraRows: [
///     SettingsRow(
///       icon: Icons.volume_up_rounded,
///       title: 'Звук',
///       trailing: Switch(value: sound, onChanged: _toggleSound),
///       onTap: () => _toggleSound(!sound),
///     ),
///   ],
/// )
/// ```
class AppearanceSettings extends StatelessWidget {
  final AppearanceLabels labels;
  final List<Color> presets;

  /// Специфичные для приложения строки, добавляемые в ту же карточку.
  final List<Widget> extraRows;

  const AppearanceSettings({
    super.key,
    this.labels = const AppearanceLabels(),
    this.presets = kDefaultThemePresets,
    this.extraRows = const [],
  });

  IconData _modeIcon(AppThemeMode m) => switch (m) {
        AppThemeMode.light => Icons.light_mode_rounded,
        AppThemeMode.dark => Icons.dark_mode_rounded,
        AppThemeMode.system => Icons.brightness_auto_rounded,
        AppThemeMode.autoTime => Icons.schedule_rounded,
      };

  String _modeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.light => labels.light,
        AppThemeMode.dark => labels.dark,
        AppThemeMode.system => labels.system,
        AppThemeMode.autoTime => labels.autoTime,
      };

  Future<void> _pickThemeMode(BuildContext context) async {
    final theme = ThemeController.instance;
    final scheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<AppThemeMode>(
      context: context,
      backgroundColor: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Text(
              labels.themeModeSheetTitle,
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            for (final m in AppThemeMode.values)
              ListTile(
                leading: Icon(_modeIcon(m)),
                title: Text(_modeLabel(m)),
                trailing: theme.mode == m
                    ? Icon(Icons.check_rounded, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) await theme.setMode(picked);
  }

  Future<void> _pickSeedColor(BuildContext context) async {
    final theme = ThemeController.instance;
    final result = await showColorPickerSheet(
      context,
      initial: theme.seedColor,
      title: labels.themeColor,
      resetTo: AppTheme.defaultSeed,
    );
    if (result != null) await theme.setSeedColor(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    // Слушаем контроллер — блок сам перестраивается при смене темы/цвета.
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final rows = <Widget>[
          SettingsRow(
            icon: _modeIcon(theme.mode),
            title: labels.themeMode,
            subtitle: _modeLabel(theme.mode),
            onTap: () => _pickThemeMode(context),
            trailing:
                Icon(Icons.chevron_right_rounded, color: scheme.outline),
          ),
          // AMOLED — только когда тема не светлая.
          if (theme.mode != AppThemeMode.light) ...[
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.contrast_rounded,
              title: labels.amoled,
              subtitle: labels.amoledSub,
              onTap: () => theme.setAmoled(!theme.amoled),
              trailing:
                  Switch(value: theme.amoled, onChanged: theme.setAmoled),
            ),
          ],
          const SettingsDivider(),
          SettingsRow(
            icon: Icons.auto_awesome_rounded,
            title: labels.dynamicColor,
            subtitle: labels.dynamicColorSub,
            onTap: () => theme.setUseDynamicColor(!theme.useDynamicColor),
            trailing: Switch(
              value: theme.useDynamicColor,
              onChanged: theme.setUseDynamicColor,
            ),
          ),
          // Свой цвет + палитры — только когда Material You выключен.
          if (!theme.useDynamicColor) ...[
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.palette_rounded,
              title: labels.themeColor,
              subtitle: theme.isDefaultSeed
                  ? labels.themeColorDefault
                  : colorToHex(theme.seedColor),
              onTap: () => _pickSeedColor(context),
              trailing: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.seedColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant, width: 2),
                ),
              ),
            ),
            ColorPresetsRow(
              presets: presets,
              selected: theme.seedColor,
              onPick: theme.setSeedColor,
              label: labels.presets,
            ),
          ],
          // Специфичные пункты приложения — в ту же карточку.
          for (final row in extraRows) ...[const SettingsDivider(), row],
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(labels.section),
            SettingsGroup(rows),
          ],
        );
      },
    );
  }
}
