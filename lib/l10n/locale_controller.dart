import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Один язык интерфейса: код и родное название (для списка выбора).
class AppLanguage {
  final String code;
  final String nativeName;
  const AppLanguage(this.code, this.nativeName);
}

/// Единый центр языков интерфейса.
///
/// Хранит выбранный язык в [SharedPreferences] и оповещает слушателей;
/// `MaterialApp` слушает контроллер и пересобирает дерево — строки через
/// `tr(...)` сразу переключаются. Развязан на голый shared_preferences, чтобы
/// копироваться в новое приложение без изменений (как [ThemeController]).
///
/// Добавить язык = запись в [languages] + колонка в словаре `strings.dart`.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  static const _kLang = 'app_language';

  /// Поддерживаемые языки интерфейса (порядок = порядок в списке выбора).
  static const List<AppLanguage> languages = [
    AppLanguage('ru', 'Русский'),
    AppLanguage('en', 'English'),
    AppLanguage('de', 'Deutsch'),
    AppLanguage('fr', 'Français'),
    AppLanguage('es', 'Español'),
    AppLanguage('it', 'Italiano'),
    AppLanguage('pt', 'Português'),
  ];

  static List<Locale> get supported =>
      [for (final l in languages) Locale(l.code)];

  static Set<String> get _codes => {for (final l in languages) l.code};

  String _code = 'en';
  bool _loaded = false;

  String get code => _code;
  Locale get locale => Locale(_code);
  bool get isLoaded => _loaded;

  /// Сопоставление страны → вероятный язык (если язык телефона не поддержан).
  static const Map<String, String> _langByCountry = {
    'RU': 'ru', 'BY': 'ru', 'KZ': 'ru', 'KG': 'ru', 'UA': 'ru',
    'DE': 'de', 'AT': 'de', 'CH': 'de', 'LI': 'de',
    'FR': 'fr', 'BE': 'fr', 'LU': 'fr', 'MC': 'fr',
    'ES': 'es', 'MX': 'es', 'AR': 'es', 'CO': 'es', 'CL': 'es',
    'PE': 'es', 'VE': 'es', 'EC': 'es', 'GT': 'es',
    'IT': 'it', 'SM': 'it',
    'PT': 'pt', 'BR': 'pt', 'AO': 'pt', 'MZ': 'pt',
  };

  /// Определяет язык по системе: сперва по языку телефона, затем по стране,
  /// иначе — английский.
  String _detectSystem() {
    final disp = WidgetsBinding.instance.platformDispatcher;
    for (final l in disp.locales) {
      final lc = l.languageCode.toLowerCase();
      if (_codes.contains(lc)) return lc;
    }
    final country = (disp.locale.countryCode ?? '').toUpperCase();
    final byCountry = _langByCountry[country];
    if (byCountry != null && _codes.contains(byCountry)) return byCountry;
    return 'en';
  }

  /// Подгружает сохранённый язык. Вызывается один раз до `runApp`.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_kLang);
    _code = (stored != null && _codes.contains(stored))
        ? stored
        : _detectSystem();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setCode(String code) async {
    if (code == _code || !_codes.contains(code)) return;
    _code = code;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString(_kLang, code);
  }
}
