import 'package:flutter/material.dart';

import 'data/app_prefs.dart';
import 'data/journal_lock.dart';
import 'data/media_store.dart';
import 'data/system_pause.dart';
import 'screens/lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';

/// Что показываем прямо сейчас.
enum _Gate { onboarding, locked, open }

/// Ворота приложения: онбординг → замок → дневник.
///
/// Замок закрывается не только при запуске, но и когда приложение уходит в
/// фон: телефон часто отдают в руки, и дневник не должен оставаться открытым
/// на столе. Задержку человек задаёт сам (по умолчанию — сразу).
class WicklyGate extends StatefulWidget {
  const WicklyGate({super.key});

  @override
  State<WicklyGate> createState() => _WicklyGateState();
}

class _WicklyGateState extends State<WicklyGate> with WidgetsBindingObserver {
  late _Gate _gate;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gate = _initialGate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static _Gate _initialGate() {
    final prefs = AppPrefs.instance;
    if (!prefs.onboarded) return _Gate.onboarding;
    return prefs.hasPin ? _Gate.locked : _Gate.open;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = AppPrefs.instance;
    if (!prefs.hasPin || _gate == _Gate.onboarding) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftAt = DateTime.now();
      // Расшифрованные копии вложений живут во временном каталоге — при уходе
      // в фон их стираем, иначе фото останутся читаемыми снаружи приложения.
      MediaStore.instance.clearTemp();
      return;
    }

    if (state == AppLifecycleState.resumed && _leftAt != null) {
      final away = DateTime.now().difference(_leftAt!).inSeconds;
      // В фон уводит и системное окно, которое позвали мы сами: запрос доступа
      // к микрофону, камера, выбор файла. Запирать после него — значит убивать
      // лист, ради которого окно и открывали.
      if (!SystemPause.active && away >= prefs.lockTimeoutSec) {
        // Разблокировки отдельных дневников живут до общего замка, иначе
        // закрытый дневник остался бы открытым после возврата с чужого экрана.
        JournalLock.forget();
        setState(() => _gate = _Gate.locked);
      }
      _leftAt = null;
    }
  }

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
      _Gate.locked => LockScreen(
          onUnlocked: () => setState(() => _gate = _Gate.open),
        ),
      _Gate.open => const ShellScreen(),
    };
  }
}
