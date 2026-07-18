import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/appearance_settings.dart';
import '../widgets/settings_scaffold.dart';
import 'settings_screen.dart';

/// Оформление: тема, AMOLED, Material You, свой цвет и размер текста.
///
/// Блок темы целиком из ДНК — он одинаковый во всех наших приложениях.
/// Своё у Wickly только размер текста: дневник читают подолгу, и «мелко»
/// здесь мешает сильнее, чем в трекере фильмов.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scale = AppPrefs.instance.textScale;

    return Scaffold(
      appBar: AppBar(title: Text(tr('appearance'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          AppearanceSettings(
            presets: kWicklyPresets,
            labels: AppearanceLabels(
              section: tr('theme'),
              themeMode: tr('theme'),
              themeModeSheetTitle: tr('theme_sheet_title'),
              light: tr('theme_light'),
              dark: tr('theme_dark'),
              system: tr('theme_system'),
              autoTime: tr('theme_auto'),
              amoled: tr('amoled'),
              amoledSub: tr('amoled_sub'),
              dynamicColor: tr('material_you'),
              dynamicColorSub: tr('material_you_sub'),
              themeColor: tr('theme_color'),
              themeColorDefault: tr('theme_color_default'),
              presets: tr('presets'),
            ),
          ),

          SettingsSection(tr('text_size')),
          SettingsGroup([
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('text_size_sample'),
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 15 * scale,
                      height: 1.45,
                      color: scheme.onSurface,
                    ),
                  ),
                  Slider(
                    value: scale,
                    min: 0.85,
                    max: 1.35,
                    divisions: 10,
                    label: '${(scale * 100).round()}%',
                    onChanged: (v) async {
                      await AppPrefs.instance.setTextScale(v);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ]),

          SettingsSection(tr('start_screen')),
          SettingsGroup([
            for (final entry in const {
              'feed': 'tab_feed',
              'calendar': 'tab_calendar',
              'map': 'tab_map',
              'media': 'tab_media',
            }.entries)
              SettingsRow(
                icon: switch (entry.key) {
                  'feed' => Icons.view_agenda_rounded,
                  'calendar' => Icons.calendar_month_rounded,
                  'map' => Icons.map_rounded,
                  _ => Icons.grid_view_rounded,
                },
                title: tr(entry.value),
                trailing: AppPrefs.instance.startScreen == entry.key
                    ? Icon(Icons.check_rounded, color: scheme.primary)
                    : null,
                onTap: () async {
                  await AppPrefs.instance.setStartScreen(entry.key);
                  if (mounted) setState(() {});
                },
              ),
          ]),
        ],
      ),
    );
  }
}
