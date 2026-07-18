import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/lock_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('Замок дневника во всех темах', (tester) async {
    await Harness.shoot(
      tester,
      'lock',
      () => LockScreen(
        onUnlocked: () {},
        now: DateTime(2026, 7, 17, 21, 41),
      ),
      // Замок с кодом и включённым отпечатком — как в макете.
      prefs: const {'lock_pin_hash': 'x', 'lock_pin_salt': 'y', 'lock_biometrics': true},
      afterPump: (t) async {
        // Набираем три цифры из четырёх — снимок ловит и пустые, и полные точки.
        for (final d in ['1', '2', '3']) {
          await t.tap(find.text(d));
          await t.pump(const Duration(milliseconds: 60));
        }
      },
    );
  });
}
