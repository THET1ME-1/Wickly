// Проверка слоя данных (SQLite + CRDT) в чистой Dart VM, где sqflite-ffi
// работает и корректно завершается (во flutter_tester изолят-фабрика виснет,
// а через `dart run` нельзя тянуть Flutter — поэтому скрипт самодостаточный и
// повторяет схему таблицы `entries`, на которую опирается EntryRepository).
//
//   dart run tool/db_smoke.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

int _pass = 0, _fail = 0;
void _check(String name, bool ok) {
  ok ? _pass++ : _fail++;
  print('  ${ok ? '✓' : '✗'} $name');
}

Future<void> main() async {
  sqfliteFfiInit();

  final crdt = await SqliteCrdt.openInMemory(
    version: 1,
    onCreate: (db, version) async {
      // Та же схема, что в AppDatabase (CRDT-колонки допишутся сами).
      await db.execute('''
        CREATE TABLE entries (
          id TEXT NOT NULL,
          journal_id TEXT NOT NULL,
          title TEXT,
          body TEXT,
          entry_date INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          mood INTEGER,
          weather TEXT,
          place TEXT,
          lat REAL,
          lon REAL,
          favorite INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (id)
        )
      ''');
    },
  );

  Future<int> count() async => (await crdt.query(
              'SELECT COUNT(*) AS c FROM entries WHERE is_deleted = 0'))
          .first['c'] as int? ??
      0;

  final now = DateTime.now().millisecondsSinceEpoch;
  _check('старт пуст', await count() == 0);

  await crdt.execute(
    'INSERT INTO entries (id, journal_id, title, entry_date, created_at, mood, favorite) '
    'VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
    ['a', 'default', 'Первая запись', now, now, 4, 0],
  );
  _check('вставка → count 1', await count() == 1);

  final row =
      (await crdt.query('SELECT * FROM entries WHERE id = ?1', ['a'])).first;
  _check('чтение title', row['title'] == 'Первая запись');
  _check('чтение mood', row['mood'] == 4);
  _check('CRDT-колонки на месте', row.containsKey('hlc') && row.containsKey('is_deleted'));

  // Реактивный поток.
  final lengths = <int>[];
  final sub = crdt
      .watch('SELECT * FROM entries WHERE is_deleted = 0')
      .listen((rows) => lengths.add(rows.length));
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await crdt.execute(
    'INSERT INTO entries (id, journal_id, title, entry_date, created_at) '
    'VALUES (?1, ?2, ?3, ?4, ?5)',
    ['b', 'default', 'Вторая', now, now],
  );
  await Future<void>.delayed(const Duration(milliseconds: 180));
  await sub.cancel();
  _check('watch дошёл до 2 (${lengths.join(",")})',
      lengths.isNotEmpty && lengths.last == 2);

  // Мягкое удаление (тумбстоун).
  await crdt.execute('DELETE FROM entries WHERE id = ?1', ['a']);
  _check('удаление → count 1', await count() == 1);
  final raw = await crdt.query('SELECT is_deleted FROM entries WHERE id = ?1', ['a']);
  _check('строка жива как тумбстоун', raw.isNotEmpty && raw.first['is_deleted'] == 1);

  // Changeset для будущего P2P-синка.
  final cs = await crdt.getChangeset();
  _check('changeset содержит entries', cs.containsKey('entries'));

  await crdt.close();

  print(_fail == 0
      ? '\n✅ Слой данных работает: $_pass проверок пройдено.'
      : '\n❌ Провалено: $_fail');
}
