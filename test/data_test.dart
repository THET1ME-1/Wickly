import 'package:flutter_test/flutter_test.dart';

import 'package:wickly/models/entry.dart';

// Чистые тесты моделей (без БД). Реальный CRDT+SQLite-конвейер проверяется
// скриптом tool/db_smoke.dart — sqlite_crdt использует изолят-фабрику sqflite,
// которая виснет именно во flutter_tester, поэтому БД гоняем в чистой Dart VM.
void main() {
  test('Entry.create заполняет id и время', () {
    final e = Entry.create(journalId: 'j1', title: 'T');
    expect(e.id, isNotEmpty);
    expect(e.journalId, 'j1');
    expect(e.title, 'T');
    expect(e.favorite, false);
    expect(e.entryDate.isBefore(DateTime.now().add(const Duration(seconds: 1))),
        true);
  });

  test('Entry round-trip через колонки', () {
    final e = Entry.create(
      journalId: 'j1',
      title: 'T',
      body: 'B',
      mood: 3,
      place: 'дом',
      lat: 55.75,
      lon: 37.62,
      favorite: true,
    );
    final back = Entry.fromRow(e.toColumns());
    expect(back.id, e.id);
    expect(back.title, 'T');
    expect(back.body, 'B');
    expect(back.mood, 3);
    expect(back.place, 'дом');
    expect(back.lat, 55.75);
    expect(back.lon, 37.62);
    expect(back.favorite, true);
  });

  test('Journal round-trip', () {
    final j = Journal.create(name: 'Личное', color: 0xFFC0863E, icon: 'book');
    final back = Journal.fromRow(j.toColumns());
    expect(back.id, j.id);
    expect(back.name, 'Личное');
    expect(back.color, 0xFFC0863E);
    expect(back.icon, 'book');
  });

  test('copyWith меняет нужное, id и createdAt неизменны', () {
    final e = Entry.create(journalId: 'j1', title: 'A', mood: 2);
    final e2 = e.copyWith(title: 'B', favorite: true);
    expect(e2.id, e.id);
    expect(e2.createdAt, e.createdAt);
    expect(e2.title, 'B');
    expect(e2.favorite, true);
    expect(e2.mood, 2);
  });
}
