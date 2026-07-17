// Проверка шифрования + слоя данных в чистой Dart VM (crypto — чистый Dart,
// sqflite-ffi работает и завершается; во flutter_tester изолят-фабрика виснет).
//
//   dart run tool/db_smoke.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:wickly/data/crypto.dart';

int _pass = 0, _fail = 0;
void _check(String n, bool ok) {
  ok ? _pass++ : _fail++;
  print('  ${ok ? '✓' : '✗'} $n');
}

Future<void> main() async {
  sqfliteFfiInit();
  const key =
      '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
  Crypto.instance.init(key);

  final crdt = await SqliteCrdt.openInMemory(
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE entries (
          id TEXT NOT NULL,
          journal_id TEXT NOT NULL,
          entry_date INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          favorite INTEGER NOT NULL DEFAULT 0,
          enc TEXT,
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

  final enc = await Crypto.instance.encryptJson(
      {'title': 'Секретный вечер', 'body': 'Личное', 'mood': 4, 'place': 'дом'});
  await crdt.execute(
    'INSERT INTO entries (id, journal_id, entry_date, created_at, favorite, enc) '
    'VALUES (?1, ?2, ?3, ?4, ?5, ?6)',
    ['a', 'default', now, now, 0, enc],
  );
  _check('вставка → count 1', await count() == 1);

  final stored =
      (await crdt.query('SELECT enc FROM entries WHERE id = ?1', ['a']))
          .first['enc'] as String;
  _check('в базе ШИФРТЕКСТ (нет "Секретный"/"Личное")',
      !stored.contains('Секретный') && !stored.contains('Личное'));

  final back = await Crypto.instance.decryptJson(stored);
  _check('расшифровка title', back['title'] == 'Секретный вечер');
  _check('расшифровка mood', back['mood'] == 4);

  // Реактивный поток.
  final lengths = <int>[];
  final sub = crdt
      .watch('SELECT id FROM entries WHERE is_deleted = 0')
      .listen((rows) => lengths.add(rows.length));
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await crdt.execute(
    'INSERT INTO entries (id, journal_id, entry_date, created_at, enc) '
    'VALUES (?1, ?2, ?3, ?4, ?5)',
    ['b', 'default', now, now, await Crypto.instance.encryptJson({'title': 'Вторая'})],
  );
  await Future<void>.delayed(const Duration(milliseconds: 180));
  await sub.cancel();
  _check('watch дошёл до 2 (${lengths.join(",")})',
      lengths.isNotEmpty && lengths.last == 2);

  // Мягкое удаление (тумбстоун).
  await crdt.execute('DELETE FROM entries WHERE id = ?1', ['a']);
  _check('удаление → count 1', await count() == 1);
  _check(
      'строка жива как тумбстоун',
      (await crdt.query('SELECT is_deleted FROM entries WHERE id = ?1', ['a']))
              .first['is_deleted'] ==
          1);

  final cs = await crdt.getChangeset();
  _check('changeset содержит entries', cs.containsKey('entries'));

  // Неверный ключ не расшифровывает (аутентификация GCM).
  Crypto.instance.init('f' * 64);
  var rejected = false;
  try {
    await Crypto.instance.decryptJson(stored);
  } catch (_) {
    rejected = true;
  }
  _check('неверный ключ отклонён', rejected);

  await crdt.close();
  print(_fail == 0
      ? '\n✅ Шифрование + слой данных: $_pass проверок пройдено.'
      : '\n❌ Провалено: $_fail');
}
