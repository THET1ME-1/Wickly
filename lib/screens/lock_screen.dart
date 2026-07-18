import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../data/app_prefs.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/pressable.dart';

/// Зачем открыт экран замка.
enum LockMode {
  /// Впустить в дневник по коду или отпечатку.
  unlock,

  /// Придумать код (в настройках включили замок).
  setPin,

  /// Проверить код перед снятием замка.
  confirmPin,
}

/// Замок дневника: часы, код из четырёх цифр и биометрия.
///
/// Экран намеренно похож на локскрин телефона: крупное время сверху, точки
/// набора и большая клавиатура под большой палец. Код хранится солёным хэшем
/// (см. [AppPrefs.setPin]), сам код никуда не пишется.
class LockScreen extends StatefulWidget {
  final LockMode mode;

  /// Вызывается, когда код принят (или задан).
  final VoidCallback onUnlocked;

  /// «Сейчас» для часов. Снаружи задаётся только в снимках экранов, чтобы
  /// картинка не менялась каждую минуту.
  final DateTime? now;

  const LockScreen({
    super.key,
    this.mode = LockMode.unlock,
    required this.onUnlocked,
    this.now,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  static const _length = 4;

  String _entered = '';
  String? _firstPin; // первый ввод при установке кода
  String? _error;
  bool _busy = false;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    if (widget.mode == LockMode.unlock && AppPrefs.instance.biometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometrics());
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  bool get _asksNewPin =>
      widget.mode == LockMode.setPin || _firstPin != null;

  String get _caption {
    if (_error != null) return _error!;
    if (widget.mode == LockMode.setPin) {
      return _firstPin == null ? tr('lock_set') : tr('lock_repeat');
    }
    return tr('lock_title');
  }

  Future<void> _biometrics() async {
    if (_busy) return;
    _busy = true;
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) return;
      final ok = await auth.authenticate(
        localizedReason: tr('lock_biometric_reason'),
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok && mounted) widget.onUnlocked();
    } catch (_) {
      // Нет сенсора, отказ или отмена — человек введёт код руками.
    } finally {
      _busy = false;
    }
  }

  void _tap(String digit) {
    if (_entered.length >= _length) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == _length) {
      // Даём последней точке закраситься, потом проверяем.
      Future.delayed(const Duration(milliseconds: 120), _submit);
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _submit() async {
    final pin = _entered;
    if (widget.mode == LockMode.setPin) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = pin;
          _entered = '';
        });
        return;
      }
      if (_firstPin != pin) {
        _reject(tr('lock_mismatch'));
        setState(() => _firstPin = null);
        return;
      }
      await AppPrefs.instance.setPin(pin);
      if (mounted) widget.onUnlocked();
      return;
    }

    if (AppPrefs.instance.checkPin(pin)) {
      widget.onUnlocked();
    } else {
      _reject(tr('lock_wrong'));
    }
  }

  void _reject(String message) {
    _shake.forward(from: 0);
    setState(() {
      _entered = '';
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final now = widget.now ?? DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  Dates.time(now),
                  style: text.displayLarge?.copyWith(
                    fontSize: 68,
                    height: 1,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Dates.dayLong(now),
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _asksNewPin ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _caption,
                  style: text.bodyMedium?.copyWith(
                    color: _error != null
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                    fontWeight: _error != null ? FontWeight.w600 : null,
                  ),
                ),
                const SizedBox(height: 18),
                _Dots(
                  filled: _entered.length,
                  total: _length,
                  shake: _shake,
                  error: _error != null,
                ),
                const Spacer(flex: 2),
                _Keypad(
                  onDigit: _tap,
                  onBackspace: _backspace,
                  onBiometrics: widget.mode == LockMode.unlock &&
                          AppPrefs.instance.biometrics
                      ? _biometrics
                      : null,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Точки набора: заполняются по цифре и вздрагивают при неверном коде.
class _Dots extends StatelessWidget {
  final int filled;
  final int total;
  final AnimationController shake;
  final bool error;

  const _Dots({
    required this.filled,
    required this.total,
    required this.shake,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) {
        // Затухающее колебание: три качка влево-вправо и остановка.
        final t = shake.value;
        final dx = t == 0 ? 0.0 : (1 - t) * 10 * _wave(t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: AppTheme.emphasized,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled
                    ? (error ? scheme.error : scheme.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: i < filled
                      ? (error ? scheme.error : scheme.primary)
                      : scheme.outlineVariant,
                  width: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static double _wave(double t) {
    // sin(3 периода) без импорта dart:math — дешёвая треугольная волна.
    final phase = (t * 3) % 1;
    return phase < 0.5 ? (phase * 4 - 1) : (3 - phase * 4);
  }
}

/// Клавиатура кода: цифры, биометрия и стирание.
class _Keypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometrics;

  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometrics,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final d in row) _Key(label: d, onTap: () => onDigit(d)),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Key(
                icon: onBiometrics == null ? null : Icons.fingerprint_rounded,
                onTap: onBiometrics,
                flat: true,
              ),
              _Key(label: '0', onTap: () => onDigit('0')),
              _Key(
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
                flat: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Одна клавиша: круглая, крупная, с цифрой Unbounded.
class _Key extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Служебные клавиши (отпечаток, стирание) — без заливки.
  final bool flat;

  const _Key({this.label, this.icon, this.onTap, this.flat = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 72.0;

    if (label == null && icon == null) {
      return const SizedBox(width: size, height: size);
    }

    return PressableScale(
      child: Material(
        color: flat ? Colors.transparent : scheme.surfaceContainerHigh,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w600,
                        fontSize: 26,
                        color: scheme.onSurface,
                      ),
                    )
                  : Icon(icon, size: 24, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
