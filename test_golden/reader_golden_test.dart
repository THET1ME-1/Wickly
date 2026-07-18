import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/theme/wickly_design.dart';
import 'package:wickly/widgets/markdown_lite.dart';

import 'harness.dart';

/// Запись из нескольких тем — то, ради чего читалка раскладывается карточками.
const _entry = '''
## Продуктивный сегодня
Дошли до старого моста, вода ещё **тёплая**. Долго сидели и смотрели, как темнеет над водой.

- [x] взять плед
- [ ] проявить плёнку

## Вечер
> Хорошо, что мы сюда дошли.

Обратно шли долго: не хотелось, чтобы этот день кончался. #лето #река
''';

void main() {
  testWidgets('Читалка: запись раскладывается на темы', (tester) async {
    await Harness.shoot(
      tester,
      'reader',
      () => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WicklyDesign.screenPad),
            child: const MarkdownBody(source: _entry, cards: true),
          ),
        ),
      ),
    );
  });

  testWidgets('Без тем текст остаётся текстом', (tester) async {
    await Harness.shoot(
      tester,
      'reader_plain',
      () => Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WicklyDesign.screenPad),
            child: const MarkdownBody(
              source: 'Короткая запись без заголовков — одна мысль, '
                  'и дробить её на блоки незачем.',
              cards: true,
            ),
          ),
        ),
      ),
    );
  });
}
