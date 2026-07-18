import 'package:flutter_test/flutter_test.dart';

import 'package:wickly/models/catalog.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/models/media.dart';

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

  test('Entry round-trip: плейнтекст-строка + payload', () {
    final e = Entry.create(journalId: 'j1', title: 'T', body: 'B', mood: 3)
        .copyWith(
      place: 'дом',
      lat: 55.75,
      lon: 37.62,
      favorite: true,
      weather: 'ясно',
      temp: 24.5,
      wordCount: 12,
      writeMs: 90000,
    );
    final back = Entry.fromStorage(e.toRowColumns(), e.toPayload());
    expect(back.id, e.id);
    expect(back.title, 'T');
    expect(back.body, 'B');
    expect(back.mood, 3);
    expect(back.place, 'дом');
    expect(back.lat, 55.75);
    expect(back.lon, 37.62);
    expect(back.favorite, true);
    expect(back.weather, 'ясно');
    expect(back.temp, 24.5);
    expect(back.wordCount, 12);
    expect(back.writeMs, 90000);
    expect(back.hasPlace, true);
  });

  test('Приватного нет в плейнтекст-колонках записи', () {
    final e = Entry.create(journalId: 'j1', title: 'Секрет', body: 'Личное');
    final row = e.toRowColumns().values.map((v) => '$v').join(' ');
    expect(row.contains('Секрет'), false);
    expect(row.contains('Личное'), false);
  });

  test('Journal round-trip: имя приезжает из payload', () {
    final j = Journal.create(name: 'Личное', color: 0xFFC0863E, icon: 'book');
    final back = Journal.fromStorage(j.toRowColumns(), j.toPayload());
    expect(back.id, j.id);
    expect(back.name, 'Личное');
    expect(back.color, 0xFFC0863E);
    expect(back.icon, 'book');
    expect(j.toRowColumns()['name'], '');
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

  test('copyWith умеет стирать настроение и место', () {
    final e = Entry.create(journalId: 'j1', mood: 4)
        .copyWith(place: 'дом', lat: 1, lon: 2);
    final cleared = e.copyWith(clearMood: true, clearPlace: true);
    expect(cleared.mood, isNull);
    expect(cleared.place, isNull);
    expect(cleared.hasPlace, false);
  });

  test('Media round-trip с EXIF', () {
    final m = Media.create(
      entryId: 'e1',
      kind: MediaKind.photo,
      file: 'abc.jpg',
      takenAt: DateTime(2026, 7, 17, 21, 10),
      lat: 59.93,
      lon: 30.31,
      ocr: 'Дворцовый мост, 1916',
    );
    final back = Media.fromStorage(m.toRowColumns(), m.toPayload());
    expect(back.kind, MediaKind.photo);
    expect(back.takenAt, DateTime(2026, 7, 17, 21, 10));
    expect(back.lat, 59.93);
    expect(back.ocr, 'Дворцовый мост, 1916');
    expect(back.isVisual, true);
  });

  test('Каталог: встроенное отличается от своего', () {
    const builtin = Emotion(
        id: 'emo_calm', name: '', kind: EmotionKind.pleasant, builtin: 'emo_calm');
    final custom = Emotion.create(name: 'азарт', kind: EmotionKind.pleasant);
    expect(builtin.isCustom, false);
    expect(custom.isCustom, true);
  });

  test('День трекера кодируется и раскодируется', () {
    final d = DateTime(2026, 7, 18);
    expect(TrackerLog.dayKey(d), 20260718);
    expect(TrackerLog.dayFromKey(20260718), d);
  });
}
