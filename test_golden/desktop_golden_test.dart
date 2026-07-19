import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/screens/appearance_screen.dart';
import 'package:wickly/screens/feed_screen.dart';
import 'package:wickly/screens/journals_screen.dart';
import 'package:wickly/screens/search_screen.dart';
import 'package:wickly/services/search_service.dart';

import 'harness.dart';
import 'samples.dart';

/// Раскладка широкого окна: лента сеткой, шапка в ряд, кнопка записи уходит
/// в боковой рельс (сам рельс живёт в оболочке — здесь только лента).
void main() {
  testWidgets('Лента на широком окне', (tester) async {
    await Harness.shoot(
      tester,
      'desktop_feed',
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
      size: Harness.desktop,
      pixelRatio: 1,
    );
  });

  testWidgets('Дневники на широком окне', (tester) async {
    Journal j(String id, String name, String cover) => Journal(
          id: id,
          name: name,
          cover: cover,
          icon: 'book',
          createdAt: Samples.today,
        );
    await Harness.shoot(
      tester,
      'desktop_journals',
      () => JournalsView(
        journals: [
          JournalTile(journal: j('1', 'Личное', 'amber'), count: 128),
          JournalTile(journal: j('2', 'Путешествия', 'teal'), count: 42),
          JournalTile(journal: j('3', 'Благодарность', 'olive'), count: 61),
          JournalTile(journal: j('4', 'Работа', 'rose'), count: 24),
          JournalTile(journal: j('5', 'Сны', 'indigo'), count: 7),
        ],
      ),
      size: Harness.desktop,
      pixelRatio: 1,
    );
  });

  testWidgets('Поиск на широком окне', (tester) async {
    final entries = Samples.feedItems().map((i) => i.entry).toList();
    await Harness.shoot(
      tester,
      'desktop_search',
      () => SearchView(
        years: const [2026, 2025],
        onSearch: (q, f) => SearchService.search(entries, q, filters: f),
      ),
      size: Harness.desktop,
      pixelRatio: 1,
      afterPump: (t) async {
        await t.enterText(find.byType(TextField), 'мост');
        await t.pump(const Duration(milliseconds: 300));
      },
    );
  });

  testWidgets('Оформление на широком окне', (tester) async {
    await Harness.shoot(
      tester,
      'desktop_appearance',
      () => const AppearanceScreen(),
      size: Harness.desktop,
      pixelRatio: 1,
    );
  });
}
