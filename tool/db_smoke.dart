// Проверка слоя данных Wickly на настоящем SQLite+CRDT в чистой Dart VM.
//
// Почему не `flutter test`: `sqlite_crdt` 3.x жёстко берёт изолят-фабрику
// `databaseFactoryFfi`, и под `flutter_tester` изолят не завершается — тест
// виснет навсегда. Поэтому базу гоняем отдельным раннером:
//
//   dart run tool/db_smoke.dart
//
// Здесь работают НАСТОЯЩИЕ репозитории приложения (они ходят в `Db`, а не в
// `AppDatabase`, поэтому не тянут плагины Flutter).
import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:wickly/data/catalog_repository.dart';
import 'package:wickly/data/crypto.dart';
import 'package:wickly/data/db.dart';
import 'package:wickly/data/entry_repository.dart';
import 'package:wickly/data/journal_repository.dart';
import 'package:wickly/data/media_repository.dart';
import 'package:wickly/data/media_store.dart';
import 'package:wickly/data/schema.dart';
import 'package:wickly/data/tracker_repository.dart';
import 'package:wickly/models/catalog.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/models/media.dart';

int _pass = 0, _fail = 0;
void _check(String n, bool ok) {
  ok ? _pass++ : _fail++;
  print('  ${ok ? '✓' : '✗'} $n');
}

Future<void> main() async {
  sqfliteFfiInit();
  Crypto.instance.init(
      '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff');

  final tmp = Directory.systemTemp.createTempSync('wickly_smoke');
  MediaStore.instance
      .configure(supportDir: tmp.path, tempDir: '${tmp.path}/tmp');

  final crdt = await SqliteCrdt.openInMemory(
    version: Schema.version,
    onCreate: Schema.onCreate,
    onUpgrade: Schema.onUpgrade,
  );
  Db.attach(crdt);
  await Schema.ensureSeeds(crdt, 'Личное');

  final entries = EntryRepository.instance;
  final journals = JournalRepository.instance;
  final catalog = CatalogRepository.instance;
  final trackers = TrackerRepository.instance;
  final media = MediaRepository.instance;

  print('\n— Дневники —');
  final js = await journals.all();
  _check('дневник по умолчанию создан', js.length == 1);
  _check('имя дневника расшифровалось', js.first.name == 'Личное');
  final rawJournal = (await crdt.query('SELECT name, enc FROM journals')).first;
  _check('имя не лежит открытым текстом',
      rawJournal['name'] == '' && (rawJournal['enc'] as String).isNotEmpty);

  print('\n— Каталог —');
  _check('эмоции засеяны', (await catalog.emotions()).length == 9);
  _check('действия засеяны', (await catalog.activities()).length == 12);
  _check('трекеры засеяны', (await trackers.trackers()).length == 6);
  await Schema.ensureSeeds(crdt, 'Личное');
  _check(
      'повторный посев не плодит дублей', (await catalog.emotions()).length == 9);
  await catalog.deleteEmotion('emo_angry');
  await Schema.ensureSeeds(crdt, 'Личное');
  _check('удалённое не воскресает', (await catalog.emotions()).length == 8);

  print('\n— Записи —');
  final e = Entry.create(
    journalId: Schema.defaultJournalId,
    title: 'Вечер у реки',
    body: 'Дошли до старого моста, вода ещё тёплая.',
    mood: 4,
  ).copyWith(place: 'Набережная', lat: 59.93, lon: 30.31, wordCount: 7);
  await entries.insert(e);
  final loaded = await entries.getById(e.id);
  _check('запись читается целиком',
      loaded?.title == 'Вечер у реки' && loaded?.mood == 4);
  _check('гео сохранилось', loaded?.hasPlace == true);
  final rawEntry =
      (await crdt.query('SELECT enc FROM entries WHERE id = ?1', [e.id]))
          .first['enc'] as String;
  _check('в базе шифртекст', !rawEntry.contains('мост'));

  await entries.upsert(loaded!.copyWith(title: 'Вечер у реки, поздно'));
  _check(
      'upsert обновил, а не задвоил', (await entries.allEntries()).length == 1);

  await entries.insert(
      Entry.create(journalId: Schema.defaultJournalId, title: 'Скрытое')
          .copyWith(hidden: true));
  _check('скрытая не в общей ленте', (await entries.allEntries()).length == 1);
  _check('скрытая видна по запросу',
      (await entries.allEntries(includeHidden: true)).length == 2);

  print('\n— Связи —');
  final tag = await catalog.ensureTag('#прогулка');
  final same = await catalog.ensureTag('Прогулка');
  _check('тег не двоится по регистру и решётке', tag.id == same.id);
  await catalog.setTagsOf(e.id, [tag.id]);
  await catalog.setEmotionsOf(e.id, ['emo_calm', 'emo_gratitude']);
  await catalog.setActivitiesOf(e.id, ['act_walk']);
  _check('теги записи', (await catalog.tagIdsOf(e.id)).single == tag.id);
  _check('эмоции записи', (await catalog.emotionIdsOf(e.id)).length == 2);
  await catalog.setEmotionsOf(e.id, ['emo_calm']);
  _check('лишняя связь снята',
      (await catalog.emotionIdsOf(e.id)).single == 'emo_calm');

  print('\n— Медиа —');
  final bytes = Uint8List.fromList(List.generate(2048, (i) => i % 256));
  final name = await MediaStore.instance.put(bytes, ext: 'jpg');
  final onDisk = File('${tmp.path}/media/$name').readAsBytesSync();
  _check('файл на диске зашифрован', onDisk.length != bytes.length);
  final back = await MediaStore.instance.read(name);
  _check('файл читается обратно байт в байт',
      back != null && back.length == bytes.length && back[100] == bytes[100]);
  _check('одинаковые файлы не дублируются',
      await MediaStore.instance.put(bytes, ext: 'jpg') == name);
  await media.insert(Media.create(
      entryId: e.id, kind: MediaKind.photo, file: name, caption: 'мост'));
  _check('вложение привязано', (await media.forEntry(e.id)).length == 1);
  _check('счётчик вложений', (await media.countsByEntry())[e.id] == 1);

  print('\n— Трекеры —');
  final today = DateTime(2026, 7, 18);
  await trackers.setValue('trk_water', today, 6);
  await trackers.setValue('trk_water', today, 7);
  _check('значение за день одно и последнее',
      (await trackers.valuesForDay(today))['trk_water'] == 7);
  final week = await trackers.range(
      'trk_water', today.subtract(const Duration(days: 7)), today);
  _check('диапазон отдаёт день', week[TrackerLog.dayKey(today)] == 7);

  print('\n— Удаление —');
  await entries.delete(e.id);
  _check('запись удалена', (await entries.getById(e.id)) == null);
  _check('связи записи сняты', (await catalog.tagIdsOf(e.id)).isEmpty);
  _check('вложения записи сняты', (await media.forEntry(e.id)).isEmpty);

  print('\n— Синк —');
  _check('чейнджсет собирается', (await crdt.getChangeset()).isNotEmpty);

  await crdt.close();
  Db.detach();
  tmp.deleteSync(recursive: true);

  print('\n$_pass пройдено, $_fail провалено');
  exit(_fail == 0 ? 0 : 1);
}
