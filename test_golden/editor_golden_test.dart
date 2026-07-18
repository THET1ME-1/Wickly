import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/editor_screen.dart';
import 'package:wickly/widgets/mood_sheet.dart';
import 'package:wickly/widgets/voice_sheet.dart';

import 'harness.dart';
import 'samples.dart';

void main() {
  testWidgets('Редактор во всех темах', (tester) async {
    await Harness.shoot(
      tester,
      'editor',
      () => EditorScreen(
        entry: Samples.entry(
          id: 'e-river',
          title: 'Вечер у реки',
          body: 'Дошли до старого моста, вода ещё **тёплая**. Долго сидели '
              'молча и смотрели, как темнеет.\n'
              '- [x] взять плед\n'
              '- [ ] проявить плёнку\n'
              '> Хорошо, что мы сюда дошли.',
          at: DateTime(2026, 7, 17, 21, 10),
          mood: 4,
          place: 'Набережная',
          weather: 'ясно',
          temp: 24,
        ),
        journalId: 'default',
      ),
    );
  });

  testWidgets('Голос и диктовка', (tester) async {
    await Harness.shoot(
      tester,
      'voice',
      () => const VoiceSheetPreview(),
    );
  });

  testWidgets('Лист настроения', (tester) async {
    await Harness.shoot(
      tester,
      'mood',
      () => MoodSheetPreview(at: DateTime(2026, 7, 17, 21, 41), mood: 4),
    );
  });
}
