import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/locale_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ОБЯЗАТЕЛЬНО до runApp — иначе первый кадр мигнёт дефолтной темой/языком.
  await ThemeController.instance.load();
  await LocaleController.instance.load();

  runApp(const WicklyApp());
}

class WicklyApp extends StatelessWidget {
  const WicklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final locale = LocaleController.instance;
    // Слушаем оба контроллера: смена темы/цвета/языка перестраивает всё дерево.
    return ListenableBuilder(
      listenable: Listenable.merge([theme, locale]),
      builder: (context, _) => DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          // Material You: если включено и система отдала схему (Android 12+) —
          // берём акцент обоев как seed и строим полную M3-схему через
          // ColorScheme.fromSeed (не сырую динамическую — иначе тональные
          // поверхности схлопываются и фоны блоков «исчезают»).
          final useDyn = theme.useDynamicColor &&
              lightDynamic != null &&
              darkDynamic != null;
          final seed = useDyn ? lightDynamic.primary : theme.seedColor;
          return MaterialApp(
            title: 'Wickly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(seed),
            darkTheme: AppTheme.dark(seed, amoled: theme.amoled),
            themeMode: theme.themeMode,
            locale: locale.locale,
            supportedLocales: LocaleController.supported,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
