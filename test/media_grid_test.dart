import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/map_screen.dart';
import 'package:wickly/models/media.dart';
import 'package:wickly/widgets/media_grid.dart';

Media _photo(String id) => Media(
      id: id,
      entryId: 'e',
      kind: MediaKind.photo,
      file: 'нет-файла.jpg',
      createdAt: DateTime(2026, 7, 17),
    );

/// В приложении сетка всегда живёт в прокрутке, поэтому и здесь даём ей
/// свободную высоту — иначе тест ловит переполнение, которого в жизни нет.
Future<void> _pump(WidgetTester tester, int count) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaGrid(
              media: [for (var i = 0; i < count; i++) _photo('m$i')],
            ),
          ),
        ),
      ),
    );

void main() {
  _mapCoversTests();
  testWidgets('До четырёх фото показываются целиком', (tester) async {
    for (final count in [1, 2, 3, 4]) {
      await _pump(tester, count);
      expect(find.textContaining('+'), findsNothing,
          reason: 'при $count фото прятать нечего');
    }
  });

  testWidgets('Лишние фото сворачиваются в «+N»', (tester) async {
    await _pump(tester, 7);
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('Пустая сетка не занимает места', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: MediaGrid(media: [])),
      ),
    ));
    expect(tester.getSize(find.byType(MediaGrid)), Size.zero);
  });
}

void _mapCoversTests() {
  // Карточка места на карте показывала градиент-заглушку: вложения ей просто
  // не передавали.
  group('Обложки мест на карте', () {
    Media m(String entry, {required int sort, MediaKind kind = MediaKind.photo}) =>
        Media.create(entryId: entry, kind: kind, file: '$entry-$sort.jpg',
            sort: sort);

    test('Берётся первое наглядное вложение записи', () {
      final covers = coversByEntry([
        m('e1', sort: 2),
        m('e1', sort: 5),
      ]);
      expect(covers['e1']!.sort, 2);
    });

    test('Обложка записи побеждает: у неё порядок ниже нуля', () {
      final covers = coversByEntry([
        m('e1', sort: 0),
        m('e1', sort: -1),
      ]);
      expect(covers['e1']!.sort, -1);
    });

    test('Голос и видео в обложку не идут', () {
      final covers = coversByEntry([
        m('e1', sort: 0, kind: MediaKind.audio),
        m('e1', sort: 1, kind: MediaKind.video),
      ]);
      expect(covers['e1'], isNull);
    });

    test('Записи без вложений в карте нет', () {
      expect(coversByEntry(const []), isEmpty);
    });
  });
}
