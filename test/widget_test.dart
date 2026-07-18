import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/data/app_prefs.dart';
import 'package:wickly/l10n/strings.dart';
import 'package:wickly/main.dart';

/// Смоук приложения без базы: репозитории отдают пустоту через гард
/// `Db.isReady`, поэтому дерево должно собираться и показывать нужные ворота.
void main() {
  testWidgets('Первый запуск открывает онбординг', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.instance.load();

    await tester.pumpWidget(const WicklyApp());
    await tester.pump();

    expect(find.text('Wickly'), findsOneWidget);
    expect(find.text(tr('onb_cta')), findsOneWidget);
  });

  testWidgets('Пройденный онбординг без кода открывает ленту', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    await AppPrefs.instance.load();

    await tester.pumpWidget(const WicklyApp());
    await tester.pump();

    expect(find.text(tr('feed_empty_title')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('Заданный код запирает дневник', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'lock_pin_hash': 'x',
      'lock_pin_salt': 'y',
    });
    await AppPrefs.instance.load();

    await tester.pumpWidget(const WicklyApp());
    await tester.pump();

    expect(find.text(tr('lock_title')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}
