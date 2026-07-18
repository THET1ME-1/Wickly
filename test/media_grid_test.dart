import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
