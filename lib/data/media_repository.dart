import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../models/media.dart';
import 'db.dart';
import 'crypto.dart';
import 'enc_cache.dart';
import 'media_store.dart';

/// Вложения записей. Файлы лежат зашифрованными в приватном каталоге
/// приложения (см. [MediaStore]), здесь — связь, порядок и метаданные.
class MediaRepository {
  MediaRepository._();
  static final MediaRepository instance = MediaRepository._();

  SqlCrdt get _db => Db.crdt;

  static const _cols =
      'id, entry_id, kind, file, thumb, sort, created_at, enc';

  Stream<List<Media>> watchForEntry(String entryId) {
    if (!Db.isReady) return Stream.value(const <Media>[]);
    return _db
        .watch(
            'SELECT $_cols FROM media WHERE entry_id = ?1 AND is_deleted = 0 '
            'ORDER BY sort, created_at',
            () => [entryId])
        .asyncMap(_decodeRows);
  }

  /// Все вложения — для медиа-сетки (свежие сверху).
  Stream<List<Media>> watchAll() {
    if (!Db.isReady) return Stream.value(const <Media>[]);
    return _db
        .watch('SELECT $_cols FROM media WHERE is_deleted = 0 '
            'ORDER BY created_at DESC')
        .asyncMap(_decodeRows);
  }

  Future<List<Media>> forEntry(String entryId) async {
    if (!Db.isReady) return const [];
    final rows = await _db.query(
      'SELECT $_cols FROM media WHERE entry_id = ?1 AND is_deleted = 0 '
      'ORDER BY sort, created_at',
      [entryId],
    );
    return _decodeRows(rows);
  }

  Future<List<Media>> all() async {
    if (!Db.isReady) return const [];
    final rows = await _db.query(
      'SELECT $_cols FROM media WHERE is_deleted = 0 ORDER BY created_at DESC',
    );
    return _decodeRows(rows);
  }

  Future<Media?> getById(String id) async {
    if (!Db.isReady) return null;
    final rows = await _db
        .query('SELECT $_cols FROM media WHERE id = ?1 AND is_deleted = 0', [id]);
    return rows.isEmpty ? null : _decode(rows.first);
  }

  /// Сколько вложений у каждой записи — бейджи «+5» на карточках ленты.
  Future<Map<String, int>> countsByEntry() async {
    if (!Db.isReady) return const {};
    final rows = await _db.query(
      'SELECT entry_id, COUNT(*) AS c FROM media WHERE is_deleted = 0 '
      'GROUP BY entry_id',
    );
    return {
      for (final r in rows) r['entry_id'] as String: (r['c'] as int?) ?? 0,
    };
  }

  Future<List<Media>> _decodeRows(List<Map<String, Object?>> rows) =>
      Future.wait(rows.map(_decode));

  Future<Media> _decode(Map<String, Object?> row) async =>
      _decodeRow(row);

  Future<Media> _decodeRow(Map<String, Object?> row) async {
    final payload = await EncCache.decode(row['enc'] as String?);
    return Media.fromStorage(row, payload ?? const {},
        readable: payload != null);
  }

  Future<void> insert(Media m) async {
    final enc = await Crypto.instance.encryptJson(m.toPayload());
    await _db.execute(
      'INSERT INTO media (id, entry_id, kind, file, thumb, sort, created_at, '
      'enc) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)',
      [
        m.id,
        m.entryId,
        m.kind.name,
        m.file,
        m.thumb,
        m.sort,
        m.createdAt.millisecondsSinceEpoch,
        enc,
      ],
    );
  }

  Future<void> update(Media m) async {
    // Нечитаемый payload затёр бы подпись, место съёмки и распознанный текст.
    if (!m.readable) return;
    final enc = await Crypto.instance.encryptJson(m.toPayload());
    await _db.execute(
      'UPDATE media SET thumb = ?1, sort = ?2, enc = ?3 WHERE id = ?4',
      [m.thumb, m.sort, enc, m.id],
    );
  }

  /// Удаляет вложение и стирает его файлы с диска (они больше никому не нужны:
  /// имя файла уникально для вложения).
  Future<void> delete(Media m) async {
    await _db.execute('DELETE FROM media WHERE id = ?1', [m.id]);
    await MediaStore.instance.deleteFile(m.file);
    if (m.thumb != null) await MediaStore.instance.deleteFile(m.thumb!);
  }

  /// Переставляет вложения в порядке переданных id.
  Future<void> reorder(List<String> ids) async {
    for (var i = 0; i < ids.length; i++) {
      await _db.execute('UPDATE media SET sort = ?1 WHERE id = ?2', [i, ids[i]]);
    }
  }
}
