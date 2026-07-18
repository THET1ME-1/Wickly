import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/app_prefs.dart';
import 'data/crypto.dart';
import 'data/db_key.dart';
import 'data/media_store.dart';
import 'l10n/locale_controller.dart';
import 'l10n/strings.dart';
import 'services/notifications_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'utils/dates.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ОБЯЗАТЕЛЬНО до runApp — иначе первый кадр мигнёт дефолтной темой/языком.
  await ThemeController.instance.load();
  await LocaleController.instance.load();
  await AppPrefs.instance.load();
  // Названия месяцев и дней недели на семи языках.
  await Dates.init();

  // Ключ шифрования из системного хранилища (Keystore/Keychain) → крипто-слой.
  Crypto.instance.init(await DbKey.getOrCreate());

  // Склад вложений: каталоги приходят снаружи, чтобы сам склад оставался
  // чистым Dart и проверялся в `tool/db_smoke.dart`.
  MediaStore.instance.configure(
    supportDir: (await getApplicationSupportDirectory()).path,
    tempDir: (await getTemporaryDirectory()).path,
  );

  // Локальное хранилище (SQLite + CRDT). Язык уже загружен — имя дефолтного
  // дневника берём локализованным.
  await AppDatabase.instance.init(defaultJournalName: tr('journal_default'));

  // Напоминания перепланируем на старте: система могла их потерять после
  // перезагрузки телефона или обновления приложения.
  unawaited(NotificationsService.reschedule());

  runApp(const WicklyApp());
}

class WicklyApp extends StatelessWidget {
  const WicklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.instance;
    final locale = LocaleController.instance;
    final prefs = AppPrefs.instance;
    // Слушаем контроллеры: смена темы, цвета, языка и размера текста
    // перестраивает всё дерево.
    return ListenableBuilder(
      listenable: Listenable.merge([theme, locale, prefs]),
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
            // Размер текста — общий множитель поверх темы: дневник читают
            // подолгу, и это единственная настройка типографики, которую мы
            // отдаём наружу.
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: prefs.textScale,
              maxScaleFactor: prefs.textScale,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const WicklyGate(),
          );
        },
      ),
    );
  }
}
