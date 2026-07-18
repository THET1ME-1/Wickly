import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/feed_screen.dart';
import 'package:wickly/services/stats_service.dart';

import 'harness.dart';
import 'samples.dart';

void main() {
  testWidgets('Лента во всех темах', (tester) async {
    await Harness.shoot(
      tester,
      'feed',
      () => FeedView(
        data: FeedData(
          items: Samples.feedItems(),
          streak: Samples.streak,
          memories: Samples.memories(),
          period: 'июль 2026',
          lastWeek: const [true, true, false, true, true, true, true],
          now: DateTime(2026, 7, 17, 21, 41),
        ),
      ),
    );
  });

  testWidgets('Лента без записей', (tester) async {
    await Harness.shoot(
      tester,
      'feed_empty',
      () => FeedView(
        data: FeedData(
          items: [],
          streak: Streak.empty,
          period: 'июль 2026',
          now: DateTime(2026, 7, 17, 21, 41),
        ),
      ),
    );
  });
}
