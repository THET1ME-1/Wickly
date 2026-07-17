import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/locale_controller.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/appearance_settings.dart';
import '../widgets/settings_scaffold.dart';

/// Палитры «бесконечных тем» Wickly. Первая — фирменная амбра
/// ([AppTheme.defaultSeed]); из каждого seed строится вся схема через
/// ColorScheme.fromSeed, плюс всегда доступен свой цвет через колор-пикер.
const List<Color> kWicklyPresets = [
  AppTheme.defaultSeed, // амбра
  Color(0xFF9C4368), // слива
  Color(0xFF1D9AA4), // бирюза
  Color(0xFF2E7D5B), // лес
  Color(0xFF5A57C0), // индиго
  Color(0xFFB0526A), // роза
  Color(0xFFC25B3A), // терракота
  Color(0xFF4F7A3A), // олива
];

/// Ссылка на исходники (публичный репозиторий).
const String kSourceUrl = 'https://github.com/THET1ME-1/Wickly';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  String get _currentLanguageName => LocaleController.languages
      .firstWhere((l) => l.code == LocaleController.instance.code,
          orElse: () => LocaleController.languages.first)
      .nativeName;

  Future<void> _pickLanguage() async {
    final scheme = Theme.of(context).colorScheme;
    final current = LocaleController.instance.code;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 14),
            Text(
              tr('language_sheet_title'),
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            for (final lang in LocaleController.languages)
              ListTile(
                title: Text(lang.nativeName),
                trailing: lang.code == current
                    ? Icon(Icons.check_rounded, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, lang.code),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) await LocaleController.instance.setCode(picked);
  }

  Future<void> _openSource() async {
    final uri = Uri.parse(kSourceUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // Оформление + бесконечные темы (блок «ДНК»).
          AppearanceSettings(
            presets: kWicklyPresets,
            labels: AppearanceLabels(
              section: tr('appearance'),
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
            extraRows: [
              SettingsRow(
                icon: Icons.translate_rounded,
                title: tr('language'),
                subtitle: _currentLanguageName,
                onTap: _pickLanguage,
                trailing:
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
              ),
            ],
          ),

          // О программе.
          SettingsSection(tr('about')),
          SettingsGroup([
            SettingsRow(
              icon: Icons.code_rounded,
              title: tr('open_source'),
              subtitle: _version.isEmpty
                  ? tr('open_source')
                  : trf('about_sub', {'v': _version}),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.link_rounded,
              title: tr('source_code'),
              subtitle: 'github.com/THET1ME-1/Wickly',
              onTap: _openSource,
              trailing:
                  Icon(Icons.open_in_new_rounded, color: scheme.outline),
            ),
          ]),
        ],
      ),
    );
  }
}
