import 'package:path_provider/path_provider.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../models/entry.dart';

/// Локальное хранилище Wickly.
///
/// Движок — SQLite; синхронизация — CRDT (метаданные слияния `hlc`, `modified`,
/// `is_deleted` добавляет [SqliteCrdt] поверх наших таблиц). База — источник
/// истины. Запросы отбирают живые строки через `WHERE is_deleted = 0`.
///
/// TODO(шифрование): `sqlite_crdt` 3.x жёстко использует `databaseFactoryFfi` и
/// не даёт хука для ключа, поэтому SQLCipher вешаем отдельным шагом (свой
/// database-factory на sqlcipher-libs). Пока БД лежит в приватной песочнице app.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'wickly.db';
  static const _schemaVersion = 1;

  /// Стабильный id дневника по умолчанию (на него ссылаются первые записи).
  static const defaultJournalId = 'default';

  SqliteCrdt? _crdt;

  SqlCrdt get crdt => _crdt!;
  bool get isReady => _crdt != null;

  /// Открывает базу приложения и гарантирует дневник по умолчанию.
  /// [defaultJournalName] — локализованное имя (передаётся из UI-слоя).
  Future<void> init({required String defaultJournalName}) async {
    if (_crdt != null) return;
    final dir = await getApplicationSupportDirectory();
    _crdt = await SqliteCrdt.open(
      '${dir.path}/$_dbName',
      version: _schemaVersion,
      onCreate: _onCreate,
    );
    await _ensureDefaultJournal(defaultJournalName);
  }

  /// Транзиентная БД в памяти — для тестов.
  Future<void> openInMemoryForTest(
      {String defaultJournalName = 'Личное'}) async {
    _crdt = await SqliteCrdt.openInMemory(
      version: _schemaVersion,
      onCreate: _onCreate,
    );
    await _ensureDefaultJournal(defaultJournalName);
  }

  Future<void> resetForTest() async {
    await _crdt?.close();
    _crdt = null;
  }

  // CREATE TABLE идёт через CrdtTableExecutor: он сам дописывает в таблицу
  // CRDT-колонки (is_deleted, hlc, node_id, modified).
  static Future<void> _onCreate(CrdtTableExecutor db, int version) async {
    await db.execute('''
      CREATE TABLE journals (
        id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER,
        icon TEXT,
        sort INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
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
    await db.execute(
        'CREATE INDEX idx_entries_date ON entries (entry_date)');
    await db.execute(
        'CREATE INDEX idx_entries_journal ON entries (journal_id)');
  }

  Future<void> _ensureDefaultJournal(String name) async {
    final rows = await crdt
        .query('SELECT id FROM journals WHERE is_deleted = 0 LIMIT 1');
    if (rows.isNotEmpty) return;
    final j = Journal(
      id: defaultJournalId,
      name: name,
      createdAt: DateTime.now(),
    );
    await crdt.execute(
      'INSERT INTO journals (id, name, color, icon, sort, created_at) '
      'VALUES (?1, ?2, ?3, ?4, ?5, ?6)',
      [j.id, j.name, j.color, j.icon, j.sort, j.createdAt.millisecondsSinceEpoch],
    );
  }
}
