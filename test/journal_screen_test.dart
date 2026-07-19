import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/data/app_prefs.dart';
import 'package:wickly/l10n/strings.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/screens/journal_screen.dart';
import 'package:wickly/utils/dates.dart';

/// Смоук экрана дневника без базы: репозитории отдают пустоту через гард
/// `Db.isReady`, поэтому дерево должно собраться и показать пустой дневник.
///
/// Раньше просмотра записей дневника не было вовсе — тап по обложке открывал
/// её правку.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPrefs.instance.load();
    await Dates.init();
  });

  testWidgets('Дневник открывается своим экраном, а не правкой', (tester) async {
    final journal = Journal(
      id: 'j-1',
      name: 'Путешествия',
      cover: 'amber',
      createdAt: DateTime(2026, 7, 19),
    );

    await tester.pumpWidget(
      MaterialApp(home: JournalScreen(journal: journal)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Путешествия'), findsOneWidget);
    expect(find.text(tr('journal_empty_title')), findsOneWidget);
    // Кнопка записи ведёт в этот же дневник.
    expect(find.text(tr('write')), findsOneWidget);
  });
}
