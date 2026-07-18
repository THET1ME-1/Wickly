import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/onboarding_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('Онбординг во всех темах', (tester) async {
    await Harness.shoot(
      tester,
      'onboarding',
      () => OnboardingScreen(onStart: () {}, onRestore: () {}),
    );
  });
}
