import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

/// Режим темы: фиксированная светлая/тёмная, по системе или авто-по-времени
/// (тёмная ночью, светлая днём).
enum AppThemeMode { light, dark, system, autoTime }

/// Единый центр цветов приложения.
///
/// Хранит выбранный пользователем seed-цвет и режим (тёмный/светлый), кладёт их
/// в [SharedPreferences] и оповещает слушателей. `MaterialApp` слушает
/// контроллер и перестраивает тему на лету — менять цвет можно из любого экрана
/// через [ThemeController.instance], без проброса колбэков по дереву.
///
/// Это канонический контроллер «ДНК». Хранение — на голом shared_preferences,
/// поэтому его можно копировать в новое приложение без изменений. Если у
/// приложения есть свой репозиторий-обёртка над prefs — можно подменить чтение
/// /запись, но набор полей и логику режимов НЕ меняем.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _kSeed = 'theme_seed_color';
  static const _kMode = 'theme_mode_raw';
  static const _kDynamic = 'theme_dynamic_color';
  static const _kAmoled = 'theme_amoled';

  Color _seedColor = AppTheme.defaultSeed;
  AppThemeMode _mode = AppThemeMode.dark;
  bool _useDynamic = false;
  bool _amoled = false;
  bool _loaded = false;

  Color get seedColor => _seedColor;
  AppThemeMode get mode => _mode;

  /// Ночь (для авто-режима): 20:00–07:00 — тёмная.
  static bool get _isNight {
    final h = DateTime.now().hour;
    return h >= 20 || h < 7;
  }

  /// «Поверхность тёмная» — для UI, где это важно (например, тумблер AMOLED).
  bool get isDark => switch (_mode) {
        AppThemeMode.light => false,
        AppThemeMode.dark => true,
        AppThemeMode.system => true,
        AppThemeMode.autoTime => _isNight,
      };

  /// Режим Material You — брать цвет из системных обоев (Android 12+).
  bool get useDynamicColor => _useDynamic;

  /// AMOLED — чистый чёрный фон в тёмной теме.
  bool get amoled => _amoled;
  bool get isLoaded => _loaded;
  ThemeMode get themeMode => switch (_mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.autoTime =>
          _isNight ? ThemeMode.dark : ThemeMode.light,
      };

  /// Цвет совпадает со стандартным фирменным?
  bool get isDefaultSeed =>
      _seedColor.toARGB32() == AppTheme.defaultSeed.toARGB32();

  /// Подгружает сохранённые настройки. Вызывается один раз до `runApp`.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final storedSeed = p.getInt(_kSeed);
    _seedColor = storedSeed == null ? AppTheme.defaultSeed : Color(storedSeed);
    final rawMode = p.getInt(_kMode);
    if (rawMode != null && rawMode >= 0 && rawMode < AppThemeMode.values.length) {
      _mode = AppThemeMode.values[rawMode];
    }
    _useDynamic = p.getBool(_kDynamic) ?? false;
    _amoled = p.getBool(_kAmoled) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    if (value == _useDynamic) return;
    _useDynamic = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_kDynamic, value);
  }

  Future<void> setAmoled(bool value) async {
    if (value == _amoled) return;
    _amoled = value;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool(_kAmoled, value);
  }

  Future<void> setSeedColor(Color color) async {
    if (color.toARGB32() == _seedColor.toARGB32()) return;
    _seedColor = color;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt(_kSeed, color.toARGB32());
  }

  Future<void> resetSeedColor() => setSeedColor(AppTheme.defaultSeed);

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    (await SharedPreferences.getInstance()).setInt(_kMode, mode.index);
  }
}
