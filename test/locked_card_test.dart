import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/data/app_prefs.dart';
import 'package:wickly/l10n/strings.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/services/feed_service.dart';
import 'package:wickly/utils/dates.dart';
import 'package:wickly/widgets/entry_card.dart';

/// Карточка записи из запертого дневника.
///
/// Раньше такая запись не показывалась НИГДЕ: ни в ленте, ни в поиске, ни в
/// календаре — написал в закрытый дневник и потерял. Теперь карточка стоит на
/// своём месте, но под блюром и с замком.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.instance.load();
    // Карточка печатает время — без словарей дат `intl` бросает исключение.
    await Dates.init();
  });

  Entry entryAt(DateTime date, {bool pinned = false}) => Entry.create(
        journalId: 'j-secret',
        title: 'Тайное',
        body: 'Текст, который нельзя прочесть из ленты',
        entryDate: date,
      ).copyWith(pinned: pinned);

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: SizedBox(width: 400, child: child)),
      );

  testWidgets('Замок вместо текста, текст не читается', (tester) async {
    final item = EntryCardItem(
      entry: entryAt(DateTime(2026, 7, 19, 10)),
      locked: true,
      journalName: 'Личное',
    );

    await tester.pumpWidget(wrap(EntryCard(item: item)));

    expect(find.text(tr('journal_locked_tap')), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    // Содержимое в дереве есть — оно и лежит под размытием, — но поверх него
    // стоит слой с замком. Имя дневника поэтому встречается дважды: смазанным
    // внизу и чётким в самом замке.
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.text('Личное'), findsNWidgets(2));
  });

  testWidgets('Обычная карточка не размывается', (tester) async {
    final item = EntryCardItem(entry: entryAt(DateTime(2026, 7, 19, 10)));

    await tester.pumpWidget(wrap(EntryCard(item: item)));

    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.text('Тайное'), findsOneWidget);
  });

  test('Запертые записи встают в ленту по дате, закреплённые сверху', () {
    final open = [
      entryAt(DateTime(2026, 7, 19, 12)),
      entryAt(DateTime(2026, 7, 17, 12)),
    ];
    final locked = [
      entryAt(DateTime(2026, 7, 18, 12)),
      entryAt(DateTime(2026, 7, 10, 12), pinned: true),
    ];

    final feed = FeedService.withLocked(open, locked);

    expect(feed.length, 4);
    expect(feed.first.pinned, isTrue, reason: 'закреплённое всплывает');
    expect(feed[1].entryDate.day, 19);
    expect(feed[2].entryDate.day, 18, reason: 'запертая встала между своими');
    expect(feed[3].entryDate.day, 17);
  });
}
