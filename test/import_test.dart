import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/services/import_service.dart';

/// Разбор чужих бэкапов проверяется на живых файлах в `tool/import_smoke.dart`;
/// здесь — на маленьких синтетических, чтобы регрессии ловились в обычном
/// прогоне без доступа к чьему-то дневнику.
void main() {
  test('Diaro: папка, запись, тег, инверсия настроения, место', () {
    const xml = '''
<data version="2">
<table name="diaro_folders"><r><uid>f1</uid><title>Дневник</title><color>#607D8B</color></r></table>
<table name="diaro_tags"><r><uid>t1</uid><title>Море</title></r></table>
<table name="diaro_locations"><r><uid>l1</uid><address>Крит</address><lat>35.3</lat><lng>25.4</lng></r></table>
<table name="diaro_entries"><r><uid>e1</uid><date>1719984376406</date><title>День</title>
<text>Текст</text><folder_uid>f1</folder_uid><location_uid>l1</location_uid>
<tags>,t1,</tags><weather_temperature>24.9</weather_temperature><mood>1</mood></r></table>
</data>''';
    final b = ImportService.parseDiaro(xml);
    expect(b.source, 'Diaro');
    expect(b.entryCount, 1);
    final j = b.journals.single;
    expect(j.name, 'Дневник');
    expect(j.color, 0xFF607D8B);
    final e = j.entries.single;
    expect(e.title, 'День');
    expect(e.body, 'Текст');
    expect(e.tags, ['Море']);
    // Diaro 1 — лучшее настроение, у Wickly лучшее — 5.
    expect(e.mood, 5);
    expect(e.place, 'Крит');
    expect(e.lat, 35.3);
    expect(e.temp, 24.9);
  });

  test('StoryPad: дата из полей, текст, теги без эмодзи, фото, флаги', () {
    const json = '''
{"version":1,"tables":{
"tags":[{"id":1,"title":"🧠 Мысли"}],
"assets":[{"id":100,"type":"image","original_source":"/x/images/100.png"}],
"stories":[{"id":"s1","year":2026,"month":4,"day":15,"hour":5,"minute":35,"second":9,
"starred":"True","pinned":"False","feeling":"in_love","tags":[1],"assets":[100],
"moved_to_bin_at":"None","permanently_deleted_at":"None",
"latest_content":{"title":"Заголовок","plain_text":"Тело записи"}}]}}''';
    final b = ImportService.parseStoryPad(json);
    expect(b.entryCount, 1);
    final e = b.journals.single.entries.single;
    expect(e.title, 'Заголовок');
    expect(e.body, 'Тело записи');
    expect(e.date, DateTime(2026, 4, 15, 5, 35, 9));
    expect(e.tags, ['Мысли']); // ведущий эмодзи убран
    expect(e.favorite, isTrue);
    expect(e.pinned, isFalse);
    expect(e.mood, 5); // in_love
    expect(e.media.single.sourceName, '100.png');
    expect(e.media.single.kind, ImportMediaKind.photo);
  });

  test('StoryPad: запись из корзины пропускается', () {
    const json = '''
{"tables":{"tags":[],"assets":[],"stories":[
{"id":"s1","year":2026,"month":1,"day":1,"moved_to_bin_at":"2026-01-02T00:00:00",
"permanently_deleted_at":"None","latest_content":{"title":null,"plain_text":"в корзине"}}]}}''';
    expect(ImportService.parseStoryPad(json).entryCount, 0);
  });

  test('Пустая запись помечается isEmpty', () {
    expect(ImportedEntry(date: DateTime(2020)).isEmpty, isTrue);
    expect(ImportedEntry(date: DateTime(2020), body: 'x').isEmpty, isFalse);
  });
}
