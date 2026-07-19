import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/calendar_screen.dart';
import 'package:wickly/screens/desk_chronicle.dart';
import 'package:wickly/screens/feed_screen.dart';
import 'package:wickly/services/stats_service.dart';
import 'package:wickly/widgets/desk_list.dart';
import 'package:wickly/widgets/desk_rail.dart';
import 'package:wickly/widgets/desk_today.dart';

import 'harness.dart';
import 'samples.dart';

/// Три раскладки широкого окна собраны из настоящих виджетов приложения —
/// снимки сверяются с макетом.
void main() {
  final tabs = [
    const DeskTab(Icons.view_agenda_outlined, Icons.view_agenda_rounded, 'Лента'),
    const DeskTab(
        Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Календарь'),
    const DeskTab(Icons.map_outlined, Icons.map_rounded, 'Карта'),
    const DeskTab(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Медиа'),
  ];

  const journals = [
    DeskJournal(id: '1', name: 'Личное', cover: 'amber', count: 128),
    DeskJournal(id: '2', name: 'Путешествия', cover: 'teal', count: 42),
    DeskJournal(id: '3', name: 'Благодарность', cover: 'olive', count: 61),
    DeskJournal(id: '4', name: 'Работа', cover: 'rose', count: 24),
    DeskJournal(id: '5', name: 'Сны', cover: 'indigo', locked: true),
  ];

  final today = TodayData(
    streak: Samples.streak,
    lastWeek: const [true, true, false, true, true, true, true],
    mood: 4,
    marks: const ['Спокойствие', 'Прогулка', 'Кофе'],
    trackers: const [
      TodayTracker(id: 'w', name: 'Вода', value: 6, goal: 8, unit: 'стак.'),
      TodayTracker(id: 's', name: 'Сон', value: 7, goal: 8, unit: 'ч'),
      TodayTracker(id: 'z', name: 'Зарядка', value: 1, goal: 1, habit: true),
    ],
    memory: Samples.memories().first,
    memoryYears: 3,
  );

  Widget rail({bool slim = false, int selected = 0, List<DeskHabit> habits = const []}) =>
      DeskRail(
        tabs: tabs,
        selected: selected,
        onSelect: (_) {},
        slim: slim,
        journals: slim ? const [] : journals,
        tags: habits.isEmpty && !slim
            ? const ['лето', 'река', 'работа', 'книги', 'семья']
            : const [],
        habits: habits,
        syncLabel: 'Синхронизировано · 12 минут назад',
      );

  testWidgets('Стол', (tester) async {
    await Harness.shoot(
      tester,
      'desk_board',
      () => Scaffold(
        body: Row(
          children: [
            rail(),
            Expanded(
              child: FeedView(
                data: FeedData(
                  items: Samples.feedItems(),
                  streak: Samples.streak,
                  memories: Samples.memories(),
                  period: 'июль 2026',
                  lastWeek: const [true, true, false, true, true, true, true],
                  now: DateTime(2026, 7, 17, 21, 41),
                ),
              ),
            ),
            DeskToday(data: today),
          ],
        ),
      ),
      size: Harness.desktop,
      pixelRatio: 1,
    );
  });

  testWidgets('Разворот', (tester) async {
    final items = Samples.feedItems();
    await Harness.shoot(
      tester,
      'desk_spread',
      () => Scaffold(
        body: Row(
          children: [
            rail(slim: true),
            DeskList(
              items: items,
              selectedId: items.first.entry.id,
              onOpen: (_) {},
              now: DateTime(2026, 7, 17, 21, 41),
            ),
            // Место читалки: сам экран записи требует базы, а раскладку
            // проверяем без неё.
            const Expanded(child: SizedBox.expand()),
          ],
        ),
      ),
      size: Harness.desktop,
      pixelRatio: 1,
    );
  });

  testWidgets('Хроника', (tester) async {
    final entries = Samples.feedItems().map((i) => i.entry).toList();
    await Harness.shoot(
      tester,
      'desk_chronicle',
      () => Scaffold(
        body: Row(
          children: [
            rail(
              selected: 1,
              habits: const [
                DeskHabit(id: 'r', name: 'Читать', days: 18),
                DeskHabit(id: 'z', name: 'Зарядка', days: 7),
              ],
            ),
            Expanded(
              child: DeskChronicle(
                data: CalendarData(
                  moodByDay: StatsService.moodByDay(entries),
                  writtenDays: StatsService.writtenDays(entries),
                  summary: StatsService.summary(
                    entries,
                    DateTime(2026, 7, 1),
                    DateTime(2026, 7, 17),
                  ),
                  streak: Samples.streak,
                  month: DateTime(2026, 7),
                  now: DateTime(2026, 7, 17, 21, 41),
                  entriesThisMonth: entries.length,
                  wordsThisMonth: 8200,
                  countByDay: {
                    for (final e in entries)
                      e.entryDate.year * 10000 +
                          e.entryDate.month * 100 +
                          e.entryDate.day: 1,
                  },
                ),
                year: const [
                  YearBar(month: 1, count: 12, mood: 3),
                  YearBar(month: 2, count: 8, mood: 3),
                  YearBar(month: 3, count: 15, mood: 4),
                  YearBar(month: 4, count: 22, mood: 4),
                  YearBar(month: 5, count: 26, mood: 5),
                  YearBar(month: 6, count: 19, mood: 4),
                  YearBar(month: 7, count: 22, mood: 5),
                  YearBar(month: 8),
                  YearBar(month: 9),
                  YearBar(month: 10),
                  YearBar(month: 11),
                  YearBar(month: 12),
                ],
                selected: DateTime(2026, 7, 17),
                onSelectDay: (_) {},
                onChangeMonth: (_) {},
                dayEntries: Samples.feedItems().take(2).toList(),
              ),
            ),
          ],
        ),
      ),
      size: Harness.desktop,
      pixelRatio: 1,
    );
  });
}
