import 'package:flutter/material.dart';

import 'data/app_prefs.dart';
import 'data/journal_lock.dart';
import 'data/media_store.dart';
import 'data/system_pause.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';

/// Что показываем прямо сейчас.
enum _Gate { onboarding, open }

/// Ворота приложения: онбординг → дневник.
///
/// Замок живёт отдельно, поверх всего навигатора ([AppLock]): он обязан
/// закрывать и открытую заметку, и редактор, а не только ленту под ними.
class WicklyGate extends StatefulWidget {
  const WicklyGate({super.key});

  @override
  State<WicklyGate> createState() => _WicklyGateState();
}

class _WicklyGateState extends State<WicklyGate> {
  late _Gate _gate =
      AppPrefs.instance.onboarded ? _Gate.open : _Gate.onboarding;

  Future<void> _finishOnboarding() async {
    await AppPrefs.instance.setOnboarded(true);
    if (mounted) setState(() => _gate = _Gate.open);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_gate) {
      _Gate.onboarding => OnboardingScreen(
          onStart: _finishOnboarding,
          // Восстановление из бэкапа живёт в настройках; на онбординге ведём
          // туда же через открытый дневник, чтобы не плодить второй путь.
          onRestore: _finishOnboarding,
        ),
      _Gate.open => const ShellScreen(),
    };
  }
}

/// Замок приложения поверх всего навигатора.
///
/// Живёт в `MaterialApp.builder`, а не подменяет `home`: замок обязан закрывать
/// любой открытый поверх ленты экран — читалку, редактор. Пока он был подменой
/// `home`, запись, открытая перед уходом в фон, оставалась ВИДНА под системным
/// окном отпечатка (её прикрывал только нативный диалог), а после разблокировки
/// её касания «умирали»: нижний маршрут под открытой заметкой перестраивался
/// дважды, и hit-test заметки ломался до пересоздания маршрута — потому и
/// «выйти и зайти» помогало. Здесь замок — непрозрачный слой в [Stack] над
/// `Navigator`: он прячет всё, что под ним, глотает касания и снимается, не
/// трогая маршрут заметки.
///
/// Замок закрывается не только при запуске, но и когда приложение уходит в
/// фон: телефон часто отдают в руки, и дневник не должен оставаться открытым
/// на столе. Задержку человек задаёт сам (по умолчанию — минута).
class AppLock extends StatefulWidget {
  final Widget child;

  const AppLock({super.key, required this.child});

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  /// Заперто ли сейчас. На старте — по наличию кода: приложение открывается
  /// сразу под замком.
  bool _locked = AppPrefs.instance.hasPin;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // Расшифрованные копии вложений живут во временном каталоге — при уходе
      // в фон их стираем, иначе фото останутся читаемыми снаружи приложения.
      // Чистим независимо от замка: кэш — про диск, а не про UI, и без PIN он
      // тоже не должен копиться расшифрованным.
      MediaStore.instance.clearTemp();
      if (AppPrefs.instance.hasPin) _leftAt = DateTime.now();
      return;
    }

    if (!AppPrefs.instance.hasPin) return;

    if (state == AppLifecycleState.resumed && _leftAt != null) {
      final away = DateTime.now().difference(_leftAt!).inSeconds;
      _leftAt = null;
      if (_locked) return;
      // В фон уводит и системное окно, которое позвали мы сами: запрос доступа
      // к микрофону, камера, выбор файла. Запирать после него — значит убивать
      // лист, ради которого окно и открывали.
      if (!SystemPause.active && away >= AppPrefs.instance.lockTimeoutSec) {
        // Разблокировки отдельных дневников живут до общего замка, иначе
        // закрытый дневник остался бы открытым после возврата с чужого экрана.
        JournalLock.forget();
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            // Непрозрачный слой глотает касания сам: под замком лежит живой
            // Navigator с открытой заметкой, и нажатия не должны проходить
            // сквозь него на её кнопки.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: LockScreen(
                onUnlocked: () => setState(() => _locked = false),
                // Забыл код — снимаем замок (записи не теряются, PIN их не
                // шифрует) и впускаем; новый код задаётся в настройках.
                onForgot: () async {
                  await AppPrefs.instance.clearPin();
                  JournalLock.forget();
                  if (mounted) setState(() => _locked = false);
                },
              ),
            ),
          ),
      ],
    );
  }
}
