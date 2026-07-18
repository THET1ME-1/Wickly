import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/reminders_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('Напоминания и подсказки', (tester) async {
    await Harness.shoot(
      tester,
      'reminders',
      () => const RemindersScreen(),
      prefs: const {
        'reminder_enabled': true,
        'reminder_minutes': 21 * 60,
        'reminder_days': ['1', '2', '3', '4', '5'],
        'memories_enabled': true,
        'prompt_pack': 'gratitude',
      },
    );
  });
}
