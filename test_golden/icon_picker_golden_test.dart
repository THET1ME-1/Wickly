import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/widgets/icon_picker_sheet.dart';

import 'harness.dart';

void main() {
  testWidgets('Полный список иконок по группам', (tester) async {
    await Harness.shoot(
      tester,
      'icon_picker',
      () => Builder(
        builder: (context) => Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: IconPickerBody(
            selected: 'coffee',
            tint: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  });

  // Сетка внутри редакторов эмоции, действия, трекера и дневника: ходовые
  // иконки плюс ячейка «весь список». Выбранная иконка здесь не из ходовых —
  // проверяем, что она встала первой и отмечена.
  testWidgets('Ходовые иконки в редакторе', (tester) async {
    await Harness.shoot(
      tester,
      'icon_choice_grid',
      () => Builder(
        builder: (context) => Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topLeft,
              child: IconChoiceGrid(
                selected: 'rocket',
                tint: Theme.of(context).colorScheme.primary,
                onPick: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  });
}
