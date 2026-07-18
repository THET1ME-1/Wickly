import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/media.dart';
import 'package:wickly/theme/wickly_design.dart';
import 'package:wickly/widgets/media_grid.dart';

import 'harness.dart';

Media _photo(String id, {int w = 1200, int h = 900}) => Media(
      id: id,
      entryId: 'e',
      kind: MediaKind.photo,
      file: 'нет-файла.jpg',
      createdAt: DateTime(2026, 7, 17),
      width: w,
      height: h,
    );

void main() {
  testWidgets('Сетка фото под разное количество', (tester) async {
    await Harness.shoot(
      tester,
      'media_grid',
      () => Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(WicklyDesign.screenPad),
          children: [
            const _Label('одна'),
            MediaGrid(media: [_photo('a')]),
            const _Label('две'),
            MediaGrid(media: [_photo('a'), _photo('b')]),
            const _Label('три'),
            MediaGrid(media: [_photo('a'), _photo('b'), _photo('c')]),
            const _Label('семь'),
            MediaGrid(media: [
              for (var i = 0; i < 7; i++) _photo('m$i'),
            ]),
          ],
        ),
      ),
    );
  });
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Text(text,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}
