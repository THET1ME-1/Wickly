import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_prefs.dart';
import '../l10n/locale_controller.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/feedback.dart';
import '../services/update_service.dart';
import '../widgets/settings_scaffold.dart';
import '../widgets/update_sheet.dart';
import 'appearance_screen.dart';
import 'catalog_manager_screen.dart';
import 'export_screen.dart';
import 'hidden_entries_screen.dart';
import 'journals_container.dart';
import 'lock_screen.dart';
import 'reminders_screen.dart';
import 'sync_screen.dart';
import 'trackers_container.dart';

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

/// Настройки: каркас из ДНК — секции-заголовки, скруглённые группы, строки с
/// чип-иконкой. Порядок секций от «каждый день» к «раз в полгода».
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _checkingUpdate = false;

  /// Есть ли на телефоне отпечаток или лицо. Пока не спросили — прячем
  /// тумблер: обещать защиту, которой нет, хуже, чем не предлагать её.
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final auth = LocalAuthentication();
      final can = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      final list = can ? await auth.getAvailableBiometrics() : const [];
      if (mounted) setState(() => _biometricsAvailable = list.isNotEmpty);
    } catch (_) {
      if (mounted) setState(() => _biometricsAvailable = false);
    }
  }

  /// Через сколько запирать: сразу, через минуту, через пять или пятнадцать.
  static const _timeouts = <int>[0, 60, 300, 900];

  String _timeoutLabel(int sec) => switch (sec) {
        0 => tr('lock_timeout_now'),
        60 => trf('lock_timeout_min', {'n': 1}),
        300 => trf('lock_timeout_min', {'n': 5}),
        _ => trf('lock_timeout_min', {'n': 15}),
      };

  Future<void> _pickLockTimeout() async {
    final scheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<int>(
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
              tr('lock_timeout'),
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            for (final sec in _timeouts)
              ListTile(
                title: Text(_timeoutLabel(sec)),
                trailing: AppPrefs.instance.lockTimeoutSec == sec
                    ? Icon(Icons.check_rounded, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, sec),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await AppPrefs.instance.setLockTimeout(picked);
    if (mounted) setState(() {});
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  String get _currentLanguageName => LocaleController.languages
      .firstWhere((l) => l.code == LocaleController.instance.code,
          orElse: () => LocaleController.languages.first)
      .nativeName;

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  /// Включение замка ведёт на экран «придумай код», выключение просит его.
  Future<void> _toggleLock(bool value) async {
    if (value) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => LockScreen(
          mode: LockMode.setPin,
          onUnlocked: () => Navigator.of(context).pop(),
        ),
      ));
    } else {
      final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (context) => LockScreen(
          onUnlocked: () => Navigator.of(context).pop(true),
        ),
      ));
      if (ok == true) await AppPrefs.instance.clearPin();
    }
    if (mounted) setState(() {});
  }

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
    if (mounted) setState(() {});
  }

  /// Ручная проверка обновления. В отличие от тихой проверки на старте здесь
  /// человек ждёт ответа, поэтому отвечаем всегда — даже «последняя версия».
  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final info = await UpdateService.checkForUpdate(_version);
      if (!mounted) return;
      if (info == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('update_latest'))));
      } else {
        await UpdateSheet.show(context, info, _version);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('update_check_failed'))));
      }
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  Future<void> _openSource() async {
    await launchUrl(Uri.parse(kSourceUrl), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefs = AppPrefs.instance;
    Widget chevron() =>
        Icon(Icons.chevron_right_rounded, color: scheme.outline);

    return Scaffold(
      appBar: AppBar(title: Text(tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          SettingsSection(tr('section_journal')),
          SettingsGroup([
            SettingsRow(
              icon: Icons.menu_book_rounded,
              title: tr('journals_and_covers'),
              onTap: () => _open(const JournalsContainer()),
              trailing: chevron(),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.mood_rounded,
              title: tr('emotions_and_activities'),
              onTap: () => _open(const CatalogManagerScreen()),
              trailing: chevron(),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.water_drop_rounded,
              title: tr('trackers'),
              onTap: () => _open(const TrackersContainer()),
              trailing: chevron(),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.notifications_rounded,
              title: tr('reminders_and_prompts'),
              onTap: () => _open(const RemindersScreen()),
              trailing: chevron(),
            ),
          ]),

          SettingsSection(tr('section_privacy')),
          SettingsGroup([
            SettingsRow(
              icon: Icons.lock_rounded,
              title: tr('lock'),
              subtitle: tr('lock_sub'),
              trailing: Switch(value: prefs.hasPin, onChanged: _toggleLock),
              onTap: () => _toggleLock(!prefs.hasPin),
            ),
            // Тумблер биометрии показываем, только если телефону есть что
            // проверять: раньше он предлагался и там, где сенсора нет вовсе,
            // и включённая «биометрия» просто ничего не делала.
            if (prefs.hasPin && _biometricsAvailable) ...[
              const SettingsDivider(),
              SettingsRow(
                icon: Icons.fingerprint_rounded,
                title: tr('lock_use_biometrics'),
                trailing: Switch(
                  value: prefs.biometrics,
                  onChanged: (v) async {
                    await prefs.setBiometrics(v);
                    if (mounted) setState(() {});
                  },
                ),
              ),
            ],
            // Через сколько запирать после ухода в фон. Настройка была в
            // хранилище, но выставить её было негде.
            if (prefs.hasPin) ...[
              const SettingsDivider(),
              SettingsRow(
                icon: Icons.timer_outlined,
                title: tr('lock_timeout'),
                subtitle: _timeoutLabel(prefs.lockTimeoutSec),
                onTap: _pickLockTimeout,
                trailing: chevron(),
              ),
            ],
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.vibration_rounded,
              title: tr('haptics'),
              subtitle: tr('haptics_sub'),
              trailing: Switch(
                value: prefs.haptics,
                onChanged: (v) async {
                  await prefs.setHaptics(v);
                  // Отклик на включение — самим откликом.
                  if (v) Haptics.commit();
                  if (mounted) setState(() {});
                },
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.visibility_off_rounded,
              title: tr('hidden_entries'),
              subtitle: tr('hidden_entries_sub'),
              onTap: () => _open(const HiddenEntriesScreen()),
              trailing: chevron(),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.wallpaper_rounded,
              title: tr('cover_banner'),
              subtitle: tr('cover_banner_sub'),
              trailing: Switch(
                value: prefs.coverBanner,
                onChanged: (v) async {
                  await prefs.setCoverBanner(v);
                  if (mounted) setState(() {});
                },
              ),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.my_location_rounded,
              title: tr('auto_context'),
              subtitle: tr('auto_context_sub'),
              trailing: Switch(
                value: prefs.autoContext,
                onChanged: (v) async {
                  await prefs.setAutoContext(v);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ]),

          SettingsSection(tr('section_data')),
          SettingsGroup([
            SettingsRow(
              icon: Icons.sync_rounded,
              title: tr('sync'),
              subtitle: tr('sync_sub'),
              onTap: () => _open(const SyncScreen()),
              trailing: chevron(),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.download_rounded,
              title: tr('export_and_backup'),
              onTap: () => _open(const ExportScreen()),
              trailing: chevron(),
            ),
          ]),

          SettingsSection(tr('appearance')),
          SettingsGroup([
            SettingsRow(
              icon: Icons.palette_rounded,
              title: tr('appearance'),
              subtitle: tr('appearance_sub'),
              onTap: () => _open(const AppearanceScreen()),
              trailing: chevron(),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.translate_rounded,
              title: tr('language'),
              subtitle: _currentLanguageName,
              onTap: _pickLanguage,
              trailing: chevron(),
            ),
          ]),

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
              icon: Icons.system_update_rounded,
              title: tr('update_check'),
              subtitle: _version.isEmpty ? null : 'Wickly $_version',
              onTap: _checkingUpdate ? null : _checkUpdate,
              trailing: _checkingUpdate
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : chevron(),
            ),
            const SettingsDivider(),
            SettingsRow(
              icon: Icons.link_rounded,
              title: tr('source_code'),
              subtitle: 'github.com/THET1ME-1/Wickly',
              onTap: _openSource,
              trailing: Icon(Icons.open_in_new_rounded, color: scheme.outline),
            ),
          ]),
        ],
      ),
    );
  }
}
