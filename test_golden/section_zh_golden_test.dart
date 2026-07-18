import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/l10n/strings.dart';
import 'package:wickly/screens/export_screen.dart';
import 'package:wickly/screens/more_screen.dart';
import 'package:wickly/screens/sync_screen.dart';

import 'harness.dart';

void main() {
  testWidgets('Синхронизация', (tester) async {
    // Фраза задана: случайная меняла бы снимок при каждом прогоне.
    await Harness.shoot(
        tester, 'sync', () => const SyncScreen(phrase: 'кедр-туман-варенье'));
  });

  testWidgets('Экспорт и бэкап', (tester) async {
    await Harness.shoot(tester, 'export', () => const ExportScreen());
  });

  testWidgets('Хаб «Ещё»', (tester) async {
    await Harness.shoot(
      tester,
      'more',
      () => MoreScreen(items: [
        MoreItem(
          icon: Icons.menu_book_rounded,
          title: tr('journals'),
          subtitle: tr('journals_and_covers'),
        ),
        MoreItem(
          icon: Icons.insights_rounded,
          title: tr('set_mood'),
          subtitle: tr('mood_x_weather'),
        ),
        MoreItem(
          icon: Icons.water_drop_rounded,
          title: tr('trackers'),
          subtitle: tr('habits'),
        ),
        MoreItem(
          icon: Icons.history_rounded,
          title: tr('on_this_day'),
          subtitle: tr('memories_morning'),
        ),
        MoreItem(
          icon: Icons.mood_rounded,
          title: tr('emotions_and_activities'),
          subtitle: tr('mood_behind'),
        ),
        MoreItem(
          icon: Icons.notifications_rounded,
          title: tr('reminders'),
          subtitle: tr('prompt_of_day'),
        ),
        MoreItem(
          icon: Icons.search_rounded,
          title: tr('search'),
          subtitle: tr('search_section_photos'),
        ),
        MoreItem(
          icon: Icons.settings_rounded,
          title: tr('settings'),
          subtitle: tr('appearance_sub'),
        ),
      ]),
    );
  });
}
