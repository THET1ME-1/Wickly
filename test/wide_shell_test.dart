import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/data/app_prefs.dart';
import 'package:wickly/main.dart';
import 'package:wickly/widgets/desk_rail.dart';

/// Смоук широкого окна: телефонный размер тесты уже ловят, а десктопная
/// раскладка до этого не проверялась ничем — и первая же поломка рельса дошла
/// до живого приложения пустым экраном.
void main() {
  testWidgets('Оболочка на широком окне собирается с рельсом', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    await AppPrefs.instance.load();
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const WicklyApp());
    await tester.pump();

    expect(find.byType(DeskRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  // Три раскладки собираются без ошибок. Пустой экран из-за упавшего layout
  // в логах не виден — только тестом.
  for (final layout in const ['board', 'spread', 'chronicle']) {
    testWidgets('Раскладка $layout собирается', (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_done': true,
        'desktop_layout': layout,
      });
      await AppPrefs.instance.load();
      tester.view
        ..physicalSize = const Size(1440, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const WicklyApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DeskRail), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
