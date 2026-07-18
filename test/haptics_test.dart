import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/data/app_prefs.dart';
import 'package:wickly/theme/feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Считаем обращения к платформе: сам факт вибрации проверить нечем, но
  /// видно, ушла ли команда.
  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add('${call.arguments}');
      }
      return null;
    });
  });

  Future<void> setEnabled(bool on) async {
    SharedPreferences.setMockInitialValues({'haptics': on});
    await AppPrefs.instance.load();
  }

  test('Включённый отклик доходит до платформы', () async {
    await setEnabled(true);
    Haptics.tap();
    Haptics.commit();
    Haptics.celebrate();
    Haptics.warn();
    await Future<void>.delayed(Duration.zero);
    expect(calls, hasLength(4));
  });

  // Настройка должна глушить отклик целиком, иначе она декоративная.
  test('Выключенный отклик молчит', () async {
    await setEnabled(false);
    Haptics.tap();
    Haptics.commit();
    Haptics.celebrate();
    Haptics.warn();
    await Future<void>.delayed(Duration.zero);
    expect(calls, isEmpty);
  });

  test('Разные действия зовут разную силу', () async {
    await setEnabled(true);
    Haptics.tap();
    Haptics.warn();
    await Future<void>.delayed(Duration.zero);
    expect(calls.first, isNot(calls.last));
  });
}
