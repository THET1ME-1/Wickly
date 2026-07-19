import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/theme/app_theme.dart';
import 'package:wickly/screens/appearance_screen.dart';
import 'package:wickly/widgets/journal_editor_sheet.dart';
import 'package:wickly/widgets/panel_route.dart';

import 'harness.dart';

/// Запись поверх ленты: на широком окне экран открывается плавающей панелью,
/// а не страницей во весь монитор.
void main() {
  testWidgets('Панель поверх ленты', (tester) async {
    await Harness.shoot(
      tester,
      'desktop_panel',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                PanelRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      leading: const Icon(Icons.close_rounded),
                      title: const Text('Вечер у реки'),
                    ),
                    body: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Дошли до старого моста, вода ещё тёплая. Долго '
                        'сидели молча и смотрели, как темнеет над водой.',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
      size: Harness.desktop,
      pixelRatio: 1,
      afterPump: (t) async {
        await t.tap(find.text('Открыть'));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });

  testWidgets('Лист выбора на широком окне — окно по центру', (tester) async {
    await Harness.shoot(
      tester,
      'desktop_sheet',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => showJournalEditor(context),
              child: const Text('Новый дневник'),
            ),
          ),
        ),
      ),
      size: Harness.desktop,
      pixelRatio: 1,
      afterPump: (t) async {
        await t.tap(find.text('Новый дневник'));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });

  testWidgets('Экран внутри панели считает ширину по панели', (tester) async {
    await Harness.shoot(
      tester,
      'desktop_panel_screen',
      () => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                PanelRoute<void>(builder: (_) => const AppearanceScreen()),
              ),
              child: const Text('Оформление'),
            ),
          ),
        ),
      ),
      size: Harness.desktop,
      pixelRatio: 1,
      afterPump: (t) async {
        await t.tap(find.text('Оформление'));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
}
