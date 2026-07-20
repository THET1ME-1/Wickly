import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../models/entry.dart';
import 'db.dart';
import 'crypto.dart';
import 'enc_cache.dart';
import 'schema.dart';

/// Дневники (журналы): «Личное», «Путешествия», «Благодарность».
///
/// Имя зашифровано, как и всё пользовательское; плейнтекстом остаются обложка,
/// цвет, порядок и флаг «под паролем» — по ним строится сетка и гейт входа.
class JournalRepository {
  JournalRepository._();
  static final JournalRepository instance = JournalRepository._();

  SqlCrdt get _db => Db.crdt;

  static const _cols =
      'id, name, color, icon, cover, locked, sort, created_at, enc';

  Stream<List<Journal>> watchJournals() {
    if (!Db.isReady) return Stream.value(const <Journal>[]);
    return _db
        .watch('SELECT $_cols FROM journals WHERE is_deleted = 0 '
            'ORDER BY sort, created_at')
        .asyncMap(_decodeRows);
  }

  Future<List<Journal>> all() async {
    if (!Db.isReady) return const [];
    final rows = await _db.query(
      'SELECT $_cols FROM journals WHERE is_deleted = 0 ORDER BY sort, created_at',
    );
    return _decodeRows(rows);
  }

  /// Куда положить новую запись: [preferred], если такой дневник жив, иначе
  /// первый по порядку, иначе дневник по умолчанию.
  ///
  /// Раньше «Записать» из ленты брало id из настроек вслепую (`?? 'default'`).
  /// Дневник могли удалить — преф о нём не знает; сид-строки `default` могло не
  /// быть вовсе (её вставляют, только когда таблица пуста). Запись получала
  /// ссылку в никуда: в ленте метка дневника не рисовалась, в сам дневник
  /// запись не попадала, а редактор показывал первый дневник в списке и потому
  /// выглядел так, будто всё в порядке.
  Future<String> resolveTarget(String? preferred) async {
    if (!Db.isReady) return Schema.defaultJournalId;
    if (preferred != null) {
      final rows = await _db.query(
        'SELECT id FROM journals WHERE id = ?1 AND is_deleted = 0',
        [preferred],
      );
      if (rows.isNotEmpty) return preferred;
    }
    final first = await _db.query(
      'SELECT id FROM journals WHERE is_deleted = 0 '
      'ORDER BY sort, created_at LIMIT 1',
    );
    return first.isEmpty
        ? Schema.defaultJournalId
        : first.first['id'] as String;
  }

  Future<Journal?> getById(String id) async {
    if (!Db.isReady) return null;
    final rows = await _db.query(
      'SELECT $_cols FROM journals WHERE id = ?1 AND is_deleted = 0',
      [id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<Journal>> _decodeRows(List<Map<String, Object?>> rows) =>
      Future.wait(rows.map(_decode));

  Future<Journal> _decode(Map<String, Object?> row) async =>
      _decodeRow(row);

  Future<Journal> _decodeRow(Map<String, Object?> row) async {
    final payload = await EncCache.decode(row['enc'] as String?);
    return Journal.fromStorage(row, payload ?? const {},
        readable: payload != null);
  }

  Future<void> insert(Journal j) async {
    final enc = await Crypto.instance.encryptJson(j.toPayload());
    await _db.execute(
      'INSERT INTO journals (id, name, color, icon, cover, locked, sort, '
      'created_at, enc) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)',
      [
        j.id,
        '',
        j.color,
        j.icon,
        j.cover,
        j.locked ? 1 : 0,
        j.sort,
        j.createdAt.millisecondsSinceEpoch,
        enc,
      ],
    );
  }

  Future<void> update(Journal j) async {
    // Нечитаемый payload (чужой ключ) затёр бы имя дневника и пароль замка.
    if (!j.readable) return;
    final enc = await Crypto.instance.encryptJson(j.toPayload());
    await _db.execute(
      'UPDATE journals SET color = ?1, icon = ?2, cover = ?3, locked = ?4, '
      'sort = ?5, enc = ?6 WHERE id = ?7',
      [j.color, j.icon, j.cover, j.locked ? 1 : 0, j.sort, enc, j.id],
    );
  }

  /// Удаляет дневник вместе с его записями (мягко, тумбстоунами).
  Future<void> delete(String id) async {
    final rows = await _db.query(
      'SELECT id FROM entries WHERE journal_id = ?1 AND is_deleted = 0',
      [id],
    );
    for (final r in rows) {
      final entryId = r['id'] as String;
      for (final table in const [
        'media',
        'entry_tags',
        'entry_emotions',
        'entry_activities',
      ]) {
        await _db.execute('DELETE FROM $table WHERE entry_id = ?1', [entryId]);
      }
    }
    await _db.execute('DELETE FROM entries WHERE journal_id = ?1', [id]);
    await _db.execute('DELETE FROM journals WHERE id = ?1', [id]);
    // Настройка «следующая запись ляжет сюда же» продолжает помнить удалённый
    // дневник — чистить её отсюда нельзя: `AppPrefs` тянет за собой Flutter, а
    // слой данных гоняется в чистой Dart VM (`tool/db_smoke.dart`). Мёртвый id
    // безвреден: [resolveTarget] проверяет его перед каждой новой записью.
  }

  /// Сколько живых записей в каждом дневнике — для подписей на обложках.
  Future<Map<String, int>> counts() async {
    if (!Db.isReady) return const {};
    final rows = await _db.query(
      'SELECT journal_id, COUNT(*) AS c FROM entries '
      'WHERE is_deleted = 0 AND hidden = 0 GROUP BY journal_id',
    );
    return {
      for (final r in rows) r['journal_id'] as String: (r['c'] as int?) ?? 0,
    };
  }
}
