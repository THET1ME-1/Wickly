import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../models/entry.dart';
import 'app_database.dart';

/// Доступ к записям дневника поверх CRDT-хранилища.
///
/// Чтение — реактивное ([watchEntries]); запись — через отдельные [insert] /
/// [update] / [delete] (удаление = тумбстоун `is_deleted`, данные не стираются
/// физически — так их можно синхронизировать и откатывать).
class EntryRepository {
  EntryRepository._();
  static final EntryRepository instance = EntryRepository._();

  SqlCrdt get _db => AppDatabase.instance.crdt;

  static const _cols =
      'id, journal_id, title, body, entry_date, created_at, mood, weather, '
      'place, lat, lon, favorite';

  /// Живой поток записей (по всем дневникам или по одному), свежие сверху.
  Stream<List<Entry>> watchEntries({String? journalId}) {
    // Защита: пока база не открыта — отдаём пустой поток (не роняем UI).
    if (!AppDatabase.instance.isReady) return Stream.value(const <Entry>[]);
    final sql = journalId == null
        ? 'SELECT * FROM entries WHERE is_deleted = 0 '
            'ORDER BY entry_date DESC, created_at DESC'
        : 'SELECT * FROM entries WHERE is_deleted = 0 AND journal_id = ?1 '
            'ORDER BY entry_date DESC, created_at DESC';
    final stream = journalId == null
        ? _db.watch(sql)
        : _db.watch(sql, () => [journalId]);
    return stream.map((rows) => rows.map(Entry.fromRow).toList());
  }

  Future<List<Entry>> allEntries() async {
    final rows = await _db.query(
      'SELECT * FROM entries WHERE is_deleted = 0 '
      'ORDER BY entry_date DESC, created_at DESC',
    );
    return rows.map(Entry.fromRow).toList();
  }

  Future<Entry?> getById(String id) async {
    final rows = await _db.query(
      'SELECT * FROM entries WHERE id = ?1 AND is_deleted = 0',
      [id],
    );
    return rows.isEmpty ? null : Entry.fromRow(rows.first);
  }

  Future<int> count() async {
    final rows =
        await _db.query('SELECT COUNT(*) AS c FROM entries WHERE is_deleted = 0');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> insert(Entry e) async {
    await _db.execute(
      'INSERT INTO entries ($_cols) '
      'VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12)',
      [
        e.id,
        e.journalId,
        e.title,
        e.body,
        e.entryDate.millisecondsSinceEpoch,
        e.createdAt.millisecondsSinceEpoch,
        e.mood,
        e.weather,
        e.place,
        e.lat,
        e.lon,
        e.favorite ? 1 : 0,
      ],
    );
  }

  Future<void> update(Entry e) async {
    await _db.execute(
      'UPDATE entries SET journal_id = ?1, title = ?2, body = ?3, '
      'entry_date = ?4, mood = ?5, weather = ?6, place = ?7, lat = ?8, '
      'lon = ?9, favorite = ?10 WHERE id = ?11',
      [
        e.journalId,
        e.title,
        e.body,
        e.entryDate.millisecondsSinceEpoch,
        e.mood,
        e.weather,
        e.place,
        e.lat,
        e.lon,
        e.favorite ? 1 : 0,
        e.id,
      ],
    );
  }

  /// Мягкое удаление (тумбстоун CRDT).
  Future<void> delete(String id) =>
      _db.execute('DELETE FROM entries WHERE id = ?1', [id]);
}
