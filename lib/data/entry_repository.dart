import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../models/entry.dart';
import 'app_database.dart';
import 'crypto.dart';

/// Доступ к записям дневника поверх CRDT-хранилища.
///
/// Приватные поля записи шифруются (AES-GCM) в колонку `enc` при записи и
/// расшифровываются при чтении. Чтение — реактивное ([watchEntries]); удаление —
/// тумбстоун (`is_deleted`), данные не стираются физически (синкабельно).
class EntryRepository {
  EntryRepository._();
  static final EntryRepository instance = EntryRepository._();

  SqlCrdt get _db => AppDatabase.instance.crdt;

  static const _cols =
      'id, journal_id, entry_date, created_at, favorite, enc';

  /// Живой поток записей (по всем дневникам или по одному), свежие сверху.
  Stream<List<Entry>> watchEntries({String? journalId}) {
    if (!AppDatabase.instance.isReady) return Stream.value(const <Entry>[]);
    final sql = journalId == null
        ? 'SELECT $_cols FROM entries WHERE is_deleted = 0 '
            'ORDER BY entry_date DESC, created_at DESC'
        : 'SELECT $_cols FROM entries WHERE is_deleted = 0 AND journal_id = ?1 '
            'ORDER BY entry_date DESC, created_at DESC';
    final stream =
        journalId == null ? _db.watch(sql) : _db.watch(sql, () => [journalId]);
    return stream.asyncMap(_decodeRows);
  }

  Future<List<Entry>> _decodeRows(List<Map<String, Object?>> rows) =>
      Future.wait(rows.map(_decode));

  Future<Entry> _decode(Map<String, Object?> row) async {
    final enc = row['enc'] as String?;
    final payload = (enc == null || enc.isEmpty)
        ? const <String, Object?>{}
        : await Crypto.instance.decryptJson(enc);
    return Entry.fromStorage(row, payload);
  }

  Future<List<Entry>> allEntries() async {
    final rows = await _db.query(
      'SELECT $_cols FROM entries WHERE is_deleted = 0 '
      'ORDER BY entry_date DESC, created_at DESC',
    );
    return _decodeRows(rows);
  }

  Future<Entry?> getById(String id) async {
    final rows = await _db.query(
      'SELECT $_cols FROM entries WHERE id = ?1 AND is_deleted = 0',
      [id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<int> count() async {
    final rows = await _db
        .query('SELECT COUNT(*) AS c FROM entries WHERE is_deleted = 0');
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> insert(Entry e) async {
    final enc = await Crypto.instance.encryptJson(e.toPayload());
    await _db.execute(
      'INSERT INTO entries (id, journal_id, entry_date, created_at, favorite, enc) '
      'VALUES (?1, ?2, ?3, ?4, ?5, ?6)',
      [
        e.id,
        e.journalId,
        e.entryDate.millisecondsSinceEpoch,
        e.createdAt.millisecondsSinceEpoch,
        e.favorite ? 1 : 0,
        enc,
      ],
    );
  }

  Future<void> update(Entry e) async {
    final enc = await Crypto.instance.encryptJson(e.toPayload());
    await _db.execute(
      'UPDATE entries SET journal_id = ?1, entry_date = ?2, favorite = ?3, '
      'enc = ?4 WHERE id = ?5',
      [
        e.journalId,
        e.entryDate.millisecondsSinceEpoch,
        e.favorite ? 1 : 0,
        enc,
        e.id,
      ],
    );
  }

  /// Мягкое удаление (тумбстоун CRDT).
  Future<void> delete(String id) =>
      _db.execute('DELETE FROM entries WHERE id = ?1', [id]);
}
