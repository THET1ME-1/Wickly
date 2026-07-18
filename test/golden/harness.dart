import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/data/app_prefs.dart';
import 'package:wickly/l10n/locale_controller.dart';
import 'package:wickly/theme/app_theme.dart';

/// Обвязка для «снимков экранов»: рендерит экран в тех же теме и шрифтах, что и
/// приложение, и складывает PNG в `test/goldens/`.
///
/// Зачем: собрать APK и посмотреть глазами — долго, а тут каждый экран
/// проверяется в трёх режимах (светлая, тёмная, AMOLED) за секунды. Обновление:
///
///   flutter test --update-goldens test/golden
class Harness {
  const Harness._();

  /// Размер экрана телефона, на котором рисовался макет.
  static const Size phone = Size(390, 844);

  static bool _fontsLoaded = false;

  /// Грузит фирменные шрифты ДНК и шрифт иконок. Без этого `flutter_test`
  /// рисует Ahem — пустые прямоугольники вместо букв и иконок.
  static Future<void> loadFonts() async {
    if (_fontsLoaded) return;
    for (final family in const ['Unbounded', 'Onest']) {
      await _load(family, 'assets/fonts/$family.ttf');
    }
    // Иконки живут в кэше SDK, а не в проекте: путь спрашиваем у самого Flutter.
    final iconsPath = _materialIconsPath();
    if (iconsPath != null) await _load('MaterialIcons', iconsPath);
    _fontsLoaded = true;
  }

  static Future<void> _load(String family, String path) async {
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  static String? _materialIconsPath() {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final candidates = [
      if (flutterRoot != null)
        '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      '${Platform.environment['HOME']}/snap/flutter/common/flutter'
          '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ];
    for (final c in candidates) {
      if (File(c).existsSync()) return c;
    }
    return null;
  }

  /// Оборачивает экран в приложение с нужной темой и языком.
  static Widget app(
    Widget home, {
    Brightness brightness = Brightness.light,
    bool amoled = false,
    Color seed = AppTheme.defaultSeed,
  }) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.light
            ? AppTheme.light(seed)
            : AppTheme.dark(seed, amoled: amoled),
        locale: LocaleController.instance.locale,
        supportedLocales: LocaleController.supported,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      );

  /// Снимает экран во всех трёх режимах темы под именем `<name>_<режим>.png`.
  static Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget Function() build, {
    Size size = phone,
    Color seed = AppTheme.defaultSeed,
    String language = 'ru',
    Map<String, Object> prefs = const {},
    Future<void> Function(WidgetTester tester)? afterPump,
  }) async {
    await loadFonts();
    // Настройки устройства подменяем в памяти: экраны спрашивают у AppPrefs,
    // включён ли отпечаток, какой стартовый экран и так далее.
    SharedPreferences.setMockInitialValues(prefs);
    await AppPrefs.instance.load();
    // Снимаем на русском: на нём читает автор, и именно он ловит переполнения
    // (русские строки длиннее английских на 15–30%).
    LocaleController.instance.setCodeForTest(language);
    tester.view
      ..physicalSize = size * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    for (final mode in const [
      ('light', Brightness.light, false),
      ('dark', Brightness.dark, false),
      ('amoled', Brightness.dark, true),
    ]) {
      // Пустой кадр между режимами: иначе Flutter переиспользует Element, и
      // состояние экрана (набранный код, выбранная вкладка) течёт из снимка
      // в снимок.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(
        build(),
        brightness: mode.$2,
        amoled: mode.$3,
        seed: seed,
      ));
      await tester.pump(const Duration(milliseconds: 700));
      if (afterPump != null) await afterPump(tester);
      await tester.pump(const Duration(milliseconds: 700));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../goldens/${name}_${mode.$1}.png'),
      );
    }
  }
}
