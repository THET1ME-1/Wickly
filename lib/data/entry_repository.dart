import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../models/entry.dart';
import 'db.dart';
import 'crypto.dart';
import 'enc_cache.dart';

/// Доступ к записям дневника поверх CRDT-хранилища.
///
/// Приватные поля записи шифруются (AES-GCM) в колонку `enc` при записи и
/// расшифровываются при чтении. Чтение — реактивное ([watchEntries]); удаление —
/// тумбстоун (`is_deleted`), данные не стираются физически (синкабельно).
///
/// Скрытые записи (`hidden`) не попадают в обычные выборки: их отдаёт только
/// явный `includeHidden: true` — после разблокировки в «Скрытых записях».
class EntryRepository {
  EntryRepository._();
  static final EntryRepository instance = EntryRepository._();

  SqlCrdt get _db => Db.crdt;

  static const _cols = 'id, journal_id, entry_date, created_at, favorite, '
      'pinned, hidden, draft, enc';

  String _where({
    String? journalId,
    bool includeHidden = false,
    bool includeDrafts = true,
  }) {
    final parts = <String>['is_deleted = 0'];
    if (!includeHidden) parts.add('hidden = 0');
    if (!includeDrafts) parts.add('draft = 0');
    if (journalId != null) parts.add('journal_id = ?1');
    return parts.join(' AND ');
  }

  /// Живой поток записей (по всем дневникам или по одному), свежие сверху.
  Stream<List<Entry>> watchEntries({
    String? journalId,
    bool includeHidden = false,
    bool includeDrafts = true,
  }) {
    if (!Db.isReady) return Stream.value(const <Entry>[]);
    final sql = 'SELECT $_cols FROM entries WHERE '
        '${_where(journalId: journalId, includeHidden: includeHidden, includeDrafts: includeDrafts)} '
        'ORDER BY entry_date DESC, created_at DESC';
    final stream = journalId == null
        ? _db.watch(sql)
        : _db.watch(sql, () => [journalId]);
    return stream.asyncMap(_decodeRows);
  }

  /// Живой поток одной записи (экран чтения обновляется сам после правок).
  Stream<Entry?> watchEntry(String id) {
    if (!Db.isReady) return Stream.value(null);
    return _db
        .watch('SELECT $_cols FROM entries WHERE id = ?1 AND is_deleted = 0',
            () => [id])
        .asyncMap((rows) async => rows.isEmpty ? null : _decode(rows.first));
  }

  Future<List<Entry>> _decodeRows(List<Map<String, Object?>> rows) =>
      Future.wait(rows.map(_decode));

  Future<Entry> _decode(Map<String, Object?> row) async =>
      Entry.fromStorage(row, await EncCache.decode(row['enc'] as String?));

  Future<List<Entry>> allEntries({
    bool includeHidden = false,
    bool includeDrafts = true,
  }) async {
    if (!Db.isReady) return const [];
    final rows = await _db.query(
      'SELECT $_cols FROM entries WHERE '
      '${_where(includeHidden: includeHidden, includeDrafts: includeDrafts)} '
      'ORDER BY entry_date DESC, created_at DESC',
    );
    return _decodeRows(rows);
  }

  Future<Entry?> getById(String id) async {
    if (!Db.isReady) return null;
    final rows = await _db.query(
      'SELECT $_cols FROM entries WHERE id = ?1 AND is_deleted = 0',
      [id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  /// Записи за конкретный календарный день.
  Future<List<Entry>> forDay(DateTime day, {bool includeHidden = false}) async {
    if (!Db.isReady) return const [];
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final rows = await _db.query(
      'SELECT $_cols FROM entries WHERE is_deleted = 0 '
      '${includeHidden ? '' : 'AND hidden = 0 '}'
      'AND entry_date >= ?1 AND entry_date < ?2 '
      'ORDER BY entry_date DESC',
      [from.millisecondsSinceEpoch, to.millisecondsSinceEpoch],
    );
    return _decodeRows(rows);
  }

  /// Записи того же дня и месяца в прошлые годы — «В этот день».
  Future<List<Entry>> onThisDay(DateTime day) async {
    final all = await allEntries(includeDrafts: false);
    return all
        .where((e) =>
            e.entryDate.month == day.month &&
            e.entryDate.day == day.day &&
            e.entryDate.year != day.year)
        .toList()
      ..sort((a, b) => b.entryDate.compareTo(a.entryDate));
  }

  Future<int> count({String? journalId}) async {
    if (!Db.isReady) return 0;
    final rows = journalId == null
        ? await _db.query(
            'SELECT COUNT(*) AS c FROM entries WHERE is_deleted = 0 AND hidden = 0')
        : await _db.query(
            'SELECT COUNT(*) AS c FROM entries WHERE is_deleted = 0 '
            'AND hidden = 0 AND journal_id = ?1',
            [journalId]);
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<void> insert(Entry e) async {
    final enc = await Crypto.instance.encryptJson(e.toPayload());
    await _db.execute(
      'INSERT INTO entries (id, journal_id, entry_date, created_at, favorite, '
      'pinned, hidden, draft, enc) '
      'VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)',
      [
        e.id,
        e.journalId,
        e.entryDate.millisecondsSinceEpoch,
        e.createdAt.millisecondsSinceEpoch,
        e.favorite ? 1 : 0,
        e.pinned ? 1 : 0,
        e.hidden ? 1 : 0,
        e.draft ? 1 : 0,
        enc,
      ],
    );
  }

  Future<void> update(Entry e) async {
    final enc = await Crypto.instance.encryptJson(e.toPayload());
    await _db.execute(
      'UPDATE entries SET journal_id = ?1, entry_date = ?2, favorite = ?3, '
      'pinned = ?4, hidden = ?5, draft = ?6, enc = ?7 WHERE id = ?8',
      [
        e.journalId,
        e.entryDate.millisecondsSinceEpoch,
        e.favorite ? 1 : 0,
        e.pinned ? 1 : 0,
        e.hidden ? 1 : 0,
        e.draft ? 1 : 0,
        enc,
        e.id,
      ],
    );
  }

  /// Создаёт запись, если её ещё нет, иначе обновляет — для автосохранения.
  Future<void> upsert(Entry e) async {
    final rows =
        await _db.query('SELECT id FROM entries WHERE id = ?1', [e.id]);
    if (rows.isEmpty) {
      await insert(e);
    } else {
      await update(e);
    }
  }

  /// Мягкое удаление (тумбстоун CRDT) вместе со связями записи.
  Future<void> delete(String id) async {
    for (final table in const [
      'media',
      'entry_tags',
      'entry_emotions',
      'entry_activities',
    ]) {
      await _db.execute('DELETE FROM $table WHERE entry_id = ?1', [id]);
    }
    await _db.execute('DELETE FROM entries WHERE id = ?1', [id]);
  }
}
