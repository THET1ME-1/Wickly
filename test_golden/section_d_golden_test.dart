import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/screens/journals_screen.dart';
import 'package:wickly/screens/memories_screen.dart';
import 'package:wickly/screens/search_screen.dart';
import 'package:wickly/services/search_service.dart';
import 'package:wickly/widgets/entry_card.dart';

import 'harness.dart';
import 'samples.dart';

void main() {
  testWidgets('Дневники', (tester) async {
    Journal j(String id, String name, String cover, {bool locked = false}) =>
        Journal(
          id: id,
          name: name,
          cover: cover,
          icon: 'book',
          locked: locked,
          createdAt: Samples.today,
        );
    await Harness.shoot(
      tester,
      'journals',
      () => JournalsView(
        journals: [
          JournalTile(journal: j('1', 'Личное', 'amber'), count: 128),
          JournalTile(journal: j('2', 'Путешествия', 'teal'), count: 42),
          JournalTile(
              journal: j('3', 'Личное+18', 'plum', locked: true), count: 9),
          JournalTile(journal: j('4', 'Благодарность', 'olive'), count: 61),
          JournalTile(journal: j('5', 'Работа', 'rose'), count: 24),
        ],
      ),
    );
  });

  testWidgets('Поиск', (tester) async {
    final entries = Samples.feedItems().map((i) => i.entry).toList();
    await Harness.shoot(
      tester,
      'search',
      () => SearchView(
        years: const [2026, 2025],
        onSearch: (q, f) => SearchService.search(entries, q, filters: f),
      ),
      afterPump: (t) async {
        await t.enterText(find.byType(TextField), 'мост');
        await t.pump(const Duration(milliseconds: 300));
      },
    );
  });

  testWidgets('В этот день', (tester) async {
    await Harness.shoot(
      tester,
      'memories',
      () => MemoriesView(
        day: DateTime(2026, 7, 17),
        memories: [
          EntryCardItem(
            entry: Samples.entry(
              id: 'm1',
              title: 'Первый день в новой квартире',
              body: 'Коробки, пустые стены и странное счастье. '
                  'Кажется, это дом.',
              at: DateTime(2023, 7, 17, 20),
              mood: 5,
              place: 'Дом',
            ),
            cover: Samples.photo('m1'),
          ),
          EntryCardItem(
            entry: Samples.entry(
              id: 'm2',
              title: 'День рождения мамы',
              body: 'Собрались все вместе, испекли торт.',
              at: DateTime(2024, 7, 17, 18),
              mood: 4,
            ),
          ),
          EntryCardItem(
            entry: Samples.entry(
              id: 'm3',
              title: 'Последний экзамен',
              body: 'Наконец-то свобода на всё лето.',
              at: DateTime(2021, 7, 17, 15),
              mood: 3,
            ),
          ),
        ],
      ),
    );
  });
}
