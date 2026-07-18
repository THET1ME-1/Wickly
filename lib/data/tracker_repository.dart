import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:uuid/uuid.dart';

import '../models/catalog.dart';
import 'db.dart';
import 'crypto.dart';
import 'enc_cache.dart';

const _uuid = Uuid();

/// Трекеры (вода, сон, шаги) и привычки + их отметки по дням.
class TrackerRepository {
  TrackerRepository._();
  static final TrackerRepository instance = TrackerRepository._();

  SqlCrdt get _db => Db.crdt;

  static const _cols =
      'id, kind, unit, goal, icon, color, sort, builtin, enc';

  Stream<List<Tracker>> watchTrackers() {
    if (!Db.isReady) return Stream.value(const <Tracker>[]);
    return _db
        .watch('SELECT $_cols FROM trackers WHERE is_deleted = 0 ORDER BY sort')
        .asyncMap((rows) => Future.wait(rows.map(_decode)));
  }

  Future<List<Tracker>> trackers() async {
    if (!Db.isReady) return const [];
    final rows = await _db
        .query('SELECT $_cols FROM trackers WHERE is_deleted = 0 ORDER BY sort');
    return Future.wait(rows.map(_decode));
  }

  Future<Tracker> _decode(Map<String, Object?> row) async =>
      Tracker.fromStorage(row, await EncCache.decode(row['enc'] as String?));

  Future<void> insert(Tracker t) async {
    await _db.execute(
      'INSERT INTO trackers (id, kind, unit, goal, icon, color, sort, builtin, '
      'enc) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)',
      [
        t.id,
        t.kind.name,
        t.unit,
        t.goal,
        t.icon,
        t.color,
        t.sort,
        t.builtin,
        await Crypto.instance.encryptJson(t.toPayload()),
      ],
    );
  }

  Future<void> update(Tracker t) async {
    await _db.execute(
      'UPDATE trackers SET kind = ?1, unit = ?2, goal = ?3, icon = ?4, '
      'color = ?5, sort = ?6, enc = ?7 WHERE id = ?8',
      [
        t.kind.name,
        t.unit,
        t.goal,
        t.icon,
        t.color,
        t.sort,
        await Crypto.instance.encryptJson(t.toPayload()),
        t.id,
      ],
    );
  }

  Future<void> delete(String id) async {
    await _db.execute('DELETE FROM tracker_logs WHERE tracker_id = ?1', [id]);
    await _db.execute('DELETE FROM trackers WHERE id = ?1', [id]);
  }

  Future<void> reorder(List<String> ids) async {
    for (var i = 0; i < ids.length; i++) {
      await _db
          .execute('UPDATE trackers SET sort = ?1 WHERE id = ?2', [i, ids[i]]);
    }
  }

  // ---------------------------- Отметки по дням ----------------------------

  /// Живой поток значений за день: `trackerId → value`.
  Stream<Map<String, double>> watchDay(DateTime day) {
    if (!Db.isReady) {
      return Stream.value(const <String, double>{});
    }
    final key = TrackerLog.dayKey(day);
    return _db
        .watch(
            'SELECT tracker_id, value FROM tracker_logs '
            'WHERE day = ?1 AND is_deleted = 0',
            () => [key])
        .map((rows) => {
              for (final r in rows)
                r['tracker_id'] as String: ((r['value'] as num?) ?? 0).toDouble(),
            });
  }

  Future<Map<String, double>> valuesForDay(DateTime day) async {
    if (!Db.isReady) return const {};
    final rows = await _db.query(
      'SELECT tracker_id, value FROM tracker_logs WHERE day = ?1 AND is_deleted = 0',
      [TrackerLog.dayKey(day)],
    );
    return {
      for (final r in rows)
        r['tracker_id'] as String: ((r['value'] as num?) ?? 0).toDouble(),
    };
  }

  /// Значения трекера за диапазон дней — недельная сетка и кольца прогресса.
  Future<Map<int, double>> range(
    String trackerId,
    DateTime from,
    DateTime to,
  ) async {
    if (!Db.isReady) return const {};
    final rows = await _db.query(
      'SELECT day, value FROM tracker_logs WHERE tracker_id = ?1 '
      'AND day >= ?2 AND day <= ?3 AND is_deleted = 0',
      [trackerId, TrackerLog.dayKey(from), TrackerLog.dayKey(to)],
    );
    return {
      for (final r in rows)
        (r['day'] as int?) ?? 0: ((r['value'] as num?) ?? 0).toDouble(),
    };
  }

  /// Ставит значение за день (одна строка на трекер+день).
  Future<void> setValue(String trackerId, DateTime day, double value) async {
    final key = TrackerLog.dayKey(day);
    final rows = await _db.query(
      'SELECT id FROM tracker_logs WHERE tracker_id = ?1 AND day = ?2',
      [trackerId, key],
    );
    if (rows.isEmpty) {
      await _db.execute(
        'INSERT INTO tracker_logs (id, tracker_id, day, value) '
        'VALUES (?1, ?2, ?3, ?4)',
        [_uuid.v4(), trackerId, key, value],
      );
    } else {
      // is_deleted = 0 воскрешает строку, если значение когда-то стирали.
      await _db.execute(
        'UPDATE tracker_logs SET value = ?1, is_deleted = 0 WHERE id = ?2',
        [value, rows.first['id'] as String],
      );
    }
  }
}
