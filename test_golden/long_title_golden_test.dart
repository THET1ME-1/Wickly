// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/theme/wickly_design.dart';
import 'package:wickly/widgets/entry_card.dart';

import 'harness.dart';
import 'samples.dart';

/// Длинные заголовки раньше жили в одну строку и обрезались многоточием —
/// в ленте было видно только начало. Снимок сторожит перенос.
void main() {
  testWidgets('Длинный заголовок переносится', (tester) async {
    await Harness.shoot(
      tester,
      'long_title',
      () => Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(WicklyDesign.screenPad),
          children: [
            EntryCard(
              item: EntryCardItem(
                entry: Samples.entry(
                  id: 'e-long',
                  title: 'Тестирую своё приложение + море, песок и '
                      'очень длинный заголовок на несколько строк',
                  body: 'Вот те вот. Недавно купил себе карты. '
                      'Они стоили 11.99 €. Крутые, качественные и красивые.',
                  at: DateTime(2026, 7, 18, 17, 29),
                  mood: 5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  });
}
