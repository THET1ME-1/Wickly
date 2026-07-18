import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:uuid/uuid.dart';

import '../models/catalog.dart';
import 'db.dart';
import 'crypto.dart';
import 'enc_cache.dart';

const _uuid = Uuid();

/// Каталог эмоций, действий и тегов + их связи с записями.
///
/// Встроенные элементы приезжают из [CatalogSeed] с ключом `builtin`: их имя
/// переводится на 7 языков и не хранится в базе. Свои — с зашифрованным именем.
class CatalogRepository {
  CatalogRepository._();
  static final CatalogRepository instance = CatalogRepository._();

  SqlCrdt get _db => Db.crdt;

  // ----------------------------- Эмоции -----------------------------

  static const _emotionCols = 'id, kind, color, icon, sort, builtin, enc';

  Stream<List<Emotion>> watchEmotions() {
    if (!Db.isReady) return Stream.value(const <Emotion>[]);
    return _db
        .watch('SELECT $_emotionCols FROM emotions WHERE is_deleted = 0 '
            'ORDER BY sort')
        .asyncMap((rows) => Future.wait(rows.map(_decodeEmotion)));
  }

  Future<List<Emotion>> emotions() async {
    if (!Db.isReady) return const [];
    final rows = await _db.query(
        'SELECT $_emotionCols FROM emotions WHERE is_deleted = 0 ORDER BY sort');
    return Future.wait(rows.map(_decodeEmotion));
  }

  Future<Emotion> _decodeEmotion(Map<String, Object?> row) async =>
      Emotion.fromStorage(row, await EncCache.decode(row['enc'] as String?));

  Future<void> insertEmotion(Emotion e) async {
    await _db.execute(
      'INSERT INTO emotions (id, kind, color, icon, sort, builtin, enc) '
      'VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
      [
        e.id,
        e.kind.name,
        e.color,
        e.icon,
        e.sort,
        e.builtin,
        await Crypto.instance.encryptJson(e.toPayload()),
      ],
    );
  }

  Future<void> updateEmotion(Emotion e) async {
    await _db.execute(
      'UPDATE emotions SET kind = ?1, color = ?2, icon = ?3, sort = ?4, '
      'enc = ?5 WHERE id = ?6',
      [
        e.kind.name,
        e.color,
        e.icon,
        e.sort,
        await Crypto.instance.encryptJson(e.toPayload()),
        e.id,
      ],
    );
  }

  Future<void> deleteEmotion(String id) async {
    await _db.execute('DELETE FROM entry_emotions WHERE emotion_id = ?1', [id]);
    await _db.execute('DELETE FROM emotions WHERE id = ?1', [id]);
  }

  Future<void> reorderEmotions(List<String> ids) async {
    for (var i = 0; i < ids.length; i++) {
      await _db.execute('UPDATE emotions SET sort = ?1 WHERE id = ?2', [i, ids[i]]);
    }
  }

  // ----------------------------- Действия -----------------------------

  static const _activityCols = 'id, category, color, icon, sort, builtin, enc';

  Stream<List<Activity>> watchActivities() {
    if (!Db.isReady) return Stream.value(const <Activity>[]);
    return _db
        .watch('SELECT $_activityCols FROM activities WHERE is_deleted = 0 '
            'ORDER BY sort')
        .asyncMap((rows) => Future.wait(rows.map(_decodeActivity)));
  }

  Future<List<Activity>> activities() async {
    if (!Db.isReady) return const [];
    final rows = await _db.query('SELECT $_activityCols FROM activities '
        'WHERE is_deleted = 0 ORDER BY sort');
    return Future.wait(rows.map(_decodeActivity));
  }

  Future<Activity> _decodeActivity(Map<String, Object?> row) async =>
      Activity.fromStorage(row, await EncCache.decode(row['enc'] as String?));

  Future<void> insertActivity(Activity a) async {
    await _db.execute(
      'INSERT INTO activities (id, category, color, icon, sort, builtin, enc) '
      'VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
      [
        a.id,
        a.category.name,
        a.color,
        a.icon,
        a.sort,
        a.builtin,
        await Crypto.instance.encryptJson(a.toPayload()),
      ],
    );
  }

  Future<void> updateActivity(Activity a) async {
    await _db.execute(
      'UPDATE activities SET category = ?1, color = ?2, icon = ?3, sort = ?4, '
      'enc = ?5 WHERE id = ?6',
      [
        a.category.name,
        a.color,
        a.icon,
        a.sort,
        await Crypto.instance.encryptJson(a.toPayload()),
        a.id,
      ],
    );
  }

  Future<void> deleteActivity(String id) async {
    await _db
        .execute('DELETE FROM entry_activities WHERE activity_id = ?1', [id]);
    await _db.execute('DELETE FROM activities WHERE id = ?1', [id]);
  }

  Future<void> reorderActivities(List<String> ids) async {
    for (var i = 0; i < ids.length; i++) {
      await _db
          .execute('UPDATE activities SET sort = ?1 WHERE id = ?2', [i, ids[i]]);
    }
  }

  // ------------------------------ Теги ------------------------------

  Future<List<Tag>> tags() async {
    if (!Db.isReady) return const [];
    final rows = await _db.query(
        'SELECT id, created_at, enc FROM tags WHERE is_deleted = 0 '
        'ORDER BY created_at DESC');
    return Future.wait(rows.map((r) async =>
        Tag.fromStorage(r, await EncCache.decode(r['enc'] as String?))));
  }

  Stream<List<Tag>> watchTags() {
    if (!Db.isReady) return Stream.value(const <Tag>[]);
    return _db
        .watch('SELECT id, created_at, enc FROM tags WHERE is_deleted = 0 '
            'ORDER BY created_at DESC')
        .asyncMap((rows) => Future.wait(rows.map((r) async =>
            Tag.fromStorage(r, await EncCache.decode(r['enc'] as String?)))));
  }

  /// Находит тег по имени (без учёта регистра) или заводит новый.
  Future<Tag> ensureTag(String name) async {
    final trimmed = name.trim().replaceAll(RegExp(r'^#'), '');
    final existing = await tags();
    for (final t in existing) {
      if (t.name.toLowerCase() == trimmed.toLowerCase()) return t;
    }
    final tag = Tag.create(trimmed);
    await _db.execute(
      'INSERT INTO tags (id, created_at, enc) VALUES (?1, ?2, ?3)',
      [
        tag.id,
        tag.createdAt.millisecondsSinceEpoch,
        await Crypto.instance.encryptJson(tag.toPayload()),
      ],
    );
    return tag;
  }

  Future<void> deleteTag(String id) async {
    await _db.execute('DELETE FROM entry_tags WHERE tag_id = ?1', [id]);
    await _db.execute('DELETE FROM tags WHERE id = ?1', [id]);
  }

  // ---------------------------- Связи записи ----------------------------

  Future<List<String>> tagIdsOf(String entryId) => _linkIds(
      'SELECT tag_id AS v FROM entry_tags WHERE entry_id = ?1 AND is_deleted = 0',
      entryId);

  Future<List<String>> emotionIdsOf(String entryId) => _linkIds(
      'SELECT emotion_id AS v FROM entry_emotions WHERE entry_id = ?1 '
      'AND is_deleted = 0',
      entryId);

  Future<List<String>> activityIdsOf(String entryId) => _linkIds(
      'SELECT activity_id AS v FROM entry_activities WHERE entry_id = ?1 '
      'AND is_deleted = 0',
      entryId);

  Future<List<String>> _linkIds(String sql, String entryId) async {
    if (!Db.isReady) return const [];
    final rows = await _db.query(sql, [entryId]);
    return rows.map((r) => r['v'] as String).toList();
  }

  /// Все связи разом — чтобы лента/поиск не делали запрос на каждую запись.
  Future<Map<String, List<String>>> allLinks(String table, String column) async {
    if (!Db.isReady) return const {};
    final rows = await _db
        .query('SELECT entry_id, $column AS v FROM $table WHERE is_deleted = 0');
    final out = <String, List<String>>{};
    for (final r in rows) {
      (out[r['entry_id'] as String] ??= []).add(r['v'] as String);
    }
    return out;
  }

  Future<void> setTagsOf(String entryId, List<String> tagIds) => _setLinks(
      'entry_tags', 'tag_id', entryId, tagIds);

  Future<void> setEmotionsOf(String entryId, List<String> emotionIds) =>
      _setLinks('entry_emotions', 'emotion_id', entryId, emotionIds);

  Future<void> setActivitiesOf(String entryId, List<String> activityIds) =>
      _setLinks('entry_activities', 'activity_id', entryId, activityIds);

  /// Приводит связи записи к переданному списку: лишние — тумбстоуном,
  /// недостающие — вставкой. Так синк не спорит о том, чего не менялось.
  Future<void> _setLinks(
    String table,
    String column,
    String entryId,
    List<String> ids,
  ) async {
    final rows = await _db.query(
      'SELECT id, $column AS v FROM $table WHERE entry_id = ?1 AND is_deleted = 0',
      [entryId],
    );
    final have = {for (final r in rows) r['v'] as String: r['id'] as String};
    final want = ids.toSet();

    for (final entry in have.entries) {
      if (!want.contains(entry.key)) {
        await _db.execute('DELETE FROM $table WHERE id = ?1', [entry.value]);
      }
    }
    for (final id in want) {
      if (have.containsKey(id)) continue;
      await _db.execute(
        'INSERT INTO $table (id, entry_id, $column) VALUES (?1, ?2, ?3)',
        [_uuid.v4(), entryId, id],
      );
    }
  }
}
