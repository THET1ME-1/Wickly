// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/screens/appearance_screen.dart';
import 'package:wickly/theme/theme_controller.dart';

import 'harness.dart';

void main() {
  // Контроллер темы читает настройки сам, поэтому подсовываем ему хранилище
  // до загрузки — иначе он полезет в неподменённый плагин.
  Future<void> loadTheme(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await ThemeController.instance.load();
  }

  testWidgets('Оформление', (tester) async {
    await loadTheme(const {});
    await Harness.shoot(tester, 'appearance', () => const AppearanceScreen());
  });

  // Material You прячет палитру и насыщенность: цвет приходит из обоев.
  testWidgets('Оформление с Material You', (tester) async {
    await loadTheme(const {'theme_dynamic_color': true});
    await Harness.shoot(
      tester,
      'appearance_dynamic',
      () => const AppearanceScreen(),
      prefs: const {'theme_dynamic_color': true},
    );
  });
}
