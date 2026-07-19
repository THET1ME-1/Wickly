import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../widgets/appearance_card.dart';
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
        padding: EdgeInsets.fromLTRB(WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 4,
            WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 24),
        children: [
          SettingsSection(tr('theme')),
          const AppearanceCard(presets: kWicklyPresets),
          const SizedBox(height: 4),

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

          // Только на широком окне: на телефоне лента всегда в одну колонку,
          // и выбирать там нечего.
          if (WicklyDesign.isWide(context)) ...[
            SettingsSection(tr('desktop')),
            SettingsGroup([
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('feed_columns'),
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 0,
                          label: Text(tr('feed_columns_auto')),
                        ),
                        for (var n = 2; n <= 6; n++)
                          ButtonSegment(value: n, label: Text('$n')),
                      ],
                      selected: {AppPrefs.instance.feedColumns},
                      onSelectionChanged: (v) async {
                        await AppPrefs.instance.setFeedColumns(v.first);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ]),
          ],

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
