import 'package:sqlite_crdt/sqlite_crdt.dart';

import 'catalog_seed.dart';

/// Схема базы и её миграции — чистый Dart, без плагинов Flutter.
///
/// Приватность: всё, что написал человек (заголовки, текст, названия дневников,
/// эмоций, тегов), лежит зашифрованным в колонке `enc` (AES-GCM, см.
/// `crypto.dart`). Плейнтекстом остаются только структурные поля, по которым
/// идут сортировка и фильтрация: даты, связи, флаги, порядок.
class Schema {
  const Schema._();

  /// v1 — журналы и записи. v2 — медиа, теги, эмоции/действия, трекеры.
  static const version = 2;

  /// Стабильный id дневника по умолчанию (на него ссылаются первые записи).
  static const defaultJournalId = 'default';

  /// Таблицы, которые вообще есть в базе. Пакет синхронизации приходит от
  /// другого устройства и задаёт имена таблиц сам; прежде чем отдать changeset
  /// в `merge` (который вставляет имя таблицы в SQL сырой интерполяцией),
  /// чужие имена сверяем с этим списком — иначе пир может писать в любую
  /// таблицу или подсунуть имя-инъекцию.
  static const knownTables = {
    'journals',
    'entries',
    'media',
    'tags',
    'entry_tags',
    'emotions',
    'activities',
    'entry_emotions',
    'entry_activities',
    'trackers',
    'tracker_logs',
  };

  // CREATE TABLE идёт через CrdtTableExecutor: он сам дописывает в таблицу
  // CRDT-колонки (is_deleted, hlc, node_id, modified).
  static Future<void> onCreate(CrdtTableExecutor db, int version) async {
    await _createV1(db);
    await _createV2(db);
  }

  static Future<void> onUpgrade(CrdtTableExecutor db, int from, int to) async {
    if (from < 2) {
      // Новые колонки старых таблиц. Имя дневника переезжает в `enc`, но
      // колонка `name` остаётся: старые строки читаются как есть.
      for (final sql in const [
        'ALTER TABLE journals ADD COLUMN cover TEXT',
        'ALTER TABLE journals ADD COLUMN locked INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE journals ADD COLUMN enc TEXT',
        'ALTER TABLE entries ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE entries ADD COLUMN hidden INTEGER NOT NULL DEFAULT 0',
        'ALTER TABLE entries ADD COLUMN draft INTEGER NOT NULL DEFAULT 0',
      ]) {
        await db.execute(sql);
      }
      await _createV2(db);
    }
  }

  static Future<void> _createV1(CrdtTableExecutor db) async {
    await db.execute('''
      CREATE TABLE journals (
        id TEXT NOT NULL,
        name TEXT,
        color INTEGER,
        icon TEXT,
        cover TEXT,
        locked INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        enc TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE entries (
        id TEXT NOT NULL,
        journal_id TEXT NOT NULL,
        entry_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        favorite INTEGER NOT NULL DEFAULT 0,
        pinned INTEGER NOT NULL DEFAULT 0,
        hidden INTEGER NOT NULL DEFAULT 0,
        draft INTEGER NOT NULL DEFAULT 0,
        enc TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_entries_date ON entries (entry_date)');
    await db
        .execute('CREATE INDEX idx_entries_journal ON entries (journal_id)');
  }

  static Future<void> _createV2(CrdtTableExecutor db) async {
    // Медиа записи: файл лежит зашифрованным на диске, здесь — только связь,
    // порядок и вид. Подпись, EXIF и распознанный текст — в `enc`.
    await db.execute('''
      CREATE TABLE media (
        id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        file TEXT NOT NULL,
        thumb TEXT,
        sort INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        enc TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('CREATE INDEX idx_media_entry ON media (entry_id)');

    await db.execute('''
      CREATE TABLE tags (
        id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        enc TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE entry_tags (
        id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
    await db
        .execute('CREATE INDEX idx_entry_tags_entry ON entry_tags (entry_id)');

    // Каталог эмоций и действий (Daylio-style). `builtin` — ключ встроенного
    // элемента: имя берётся из словаря и переводится на 7 языков. Как только
    // человек переименовал — имя ложится в зашифрованный `enc` и побеждает.
    await db.execute('''
      CREATE TABLE emotions (
        id TEXT NOT NULL,
        kind TEXT NOT NULL,
        color INTEGER,
        icon TEXT,
        sort INTEGER NOT NULL DEFAULT 0,
        builtin TEXT,
        enc TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE activities (
        id TEXT NOT NULL,
        category TEXT NOT NULL,
        color INTEGER,
        icon TEXT,
        sort INTEGER NOT NULL DEFAULT 0,
        builtin TEXT,
        enc TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE entry_emotions (
        id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        emotion_id TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_entry_emotions_entry ON entry_emotions (entry_id)');
    await db.execute('''
      CREATE TABLE entry_activities (
        id TEXT NOT NULL,
        entry_id TEXT NOT NULL,
        activity_id TEXT NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute(
        'CREATE INDEX idx_entry_activities_entry ON entry_activities (entry_id)');

    // Трекеры и привычки: значение за день лежит в `tracker_logs`,
    // день — целым yyyymmdd (сравнимо и сортируемо без часовых поясов).
    await db.execute('''
      CREATE TABLE trackers (
        id TEXT NOT NULL,
        kind TEXT NOT NULL,
        unit TEXT,
        goal REAL,
        icon TEXT,
        color INTEGER,
        sort INTEGER NOT NULL DEFAULT 0,
        builtin TEXT,
        enc TEXT,
        PRIMARY KEY (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE tracker_logs (
        id TEXT NOT NULL,
        tracker_id TEXT NOT NULL,
        day INTEGER NOT NULL,
        value REAL NOT NULL,
        PRIMARY KEY (id)
      )
    ''');
    await db
        .execute('CREATE INDEX idx_tracker_logs_day ON tracker_logs (day)');
  }

  /// Дневник по умолчанию и стартовый каталог эмоций/действий/трекеров.
  static Future<void> ensureSeeds(
    SqlCrdt crdt,
    String defaultJournalName,
  ) async {
    final journals = await crdt
        .query('SELECT id FROM journals WHERE is_deleted = 0 LIMIT 1');
    if (journals.isEmpty) {
      await crdt.execute(
        'INSERT INTO journals (id, name, color, icon, cover, locked, sort, '
        'created_at, enc) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)',
        [
          defaultJournalId,
          // Пустая строка, а не NULL: в базах, доехавших с v1, у колонки
          // `name` осталось ограничение NOT NULL. Имя живёт в `enc`.
          '',
          null,
          'book',
          'amber',
          0,
          0,
          DateTime.now().millisecondsSinceEpoch,
          await CatalogSeed.encName(defaultJournalName),
        ],
      );
    }
    await CatalogSeed.ensure(crdt);
  }
}
