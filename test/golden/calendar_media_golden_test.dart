import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/media.dart';
import 'package:wickly/screens/calendar_screen.dart';
import 'package:wickly/screens/media_screen.dart';
import 'package:wickly/services/stats_service.dart';

import 'harness.dart';
import 'samples.dart';

void main() {
  testWidgets('Календарь настроения во всех темах', (tester) async {
    final month = Samples.month();
    final now = DateTime(2026, 7, 17, 21, 41);
    await Harness.shoot(
      tester,
      'calendar',
      () => CalendarView(
        data: CalendarData(
          moodByDay: StatsService.moodByDay(month),
          writtenDays: StatsService.writtenDays(month),
          summary: StatsService.summary(
              month, DateTime(2026, 7, 1), DateTime(2026, 7, 31)),
          streak: Samples.streak,
          month: DateTime(2026, 7),
          now: now,
        ),
      ),
    );
  });

  testWidgets('Медиа-сетка во всех темах', (tester) async {
    final media = [
      for (var i = 0; i < 11; i++)
        Media(
          id: 'p$i',
          entryId: 'e$i',
          kind: i == 1 ? MediaKind.video : MediaKind.photo,
          file: 'нет-файла.jpg',
          createdAt: DateTime(2026, 7, 20 - i),
        ),
      for (var i = 0; i < 3; i++)
        Media(
          id: 'j$i',
          entryId: 'e$i',
          kind: MediaKind.photo,
          file: 'нет-файла.jpg',
          createdAt: DateTime(2026, 6, 20 - i),
        ),
    ];
    await Harness.shoot(tester, 'media', () => MediaView(media: media));
  });
}
