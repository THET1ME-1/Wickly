import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../models/catalog.dart';
import 'crypto.dart';

/// Стартовый каталог: эмоции, действия и трекеры, которые есть у человека с
/// первого запуска. Дальше он их переименовывает, перекрашивает, удаляет и
/// заводит свои — см. экран «Эмоции и действия».
///
/// У встроенных элементов `builtin` — ключ словаря, поэтому имя переводится на
/// все 7 языков и **не хранится** в базе. Как только элемент переименовали,
/// имя ложится в зашифрованный `enc` и побеждает ключ.
class CatalogSeed {
  const CatalogSeed._();

  /// Помощник для мест, где нужно записать одно зашифрованное имя.
  static Future<String> encName(String name) =>
      Crypto.instance.encryptJson({'name': name});

  static const emotions = <_SeedEmotion>[
    _SeedEmotion('emo_calm', EmotionKind.pleasant, 'calm'),
    _SeedEmotion('emo_joy', EmotionKind.pleasant, 'star'),
    _SeedEmotion('emo_gratitude', EmotionKind.pleasant, 'leaf'),
    _SeedEmotion('emo_inspiration', EmotionKind.pleasant, 'idea'),
    _SeedEmotion('emo_love', EmotionKind.pleasant, 'heart'),
    _SeedEmotion('emo_tired', EmotionKind.hard, 'moon'),
    _SeedEmotion('emo_anxiety', EmotionKind.hard, 'pulse'),
    _SeedEmotion('emo_sad', EmotionKind.hard, 'water'),
    _SeedEmotion('emo_angry', EmotionKind.hard, 'flame'),
  ];

  static const activities = <_SeedActivity>[
    _SeedActivity('act_friends', ActivityCategory.people, 'people'),
    _SeedActivity('act_family', ActivityCategory.people, 'home'),
    _SeedActivity('act_date', ActivityCategory.people, 'heart'),
    _SeedActivity('act_sport', ActivityCategory.body, 'sport'),
    _SeedActivity('act_walk', ActivityCategory.body, 'place'),
    _SeedActivity('act_sleep', ActivityCategory.body, 'moon'),
    _SeedActivity('act_cooking', ActivityCategory.home, 'cooking'),
    _SeedActivity('act_work', ActivityCategory.home, 'work'),
    _SeedActivity('act_shopping', ActivityCategory.home, 'shopping'),
    _SeedActivity('act_coffee', ActivityCategory.rest, 'coffee'),
    _SeedActivity('act_movie', ActivityCategory.rest, 'movie'),
    _SeedActivity('act_book', ActivityCategory.rest, 'book'),
  ];

  static const trackers = <_SeedTracker>[
    _SeedTracker('trk_water', TrackerKind.number, 'water', 'unit_glasses', 8),
    _SeedTracker('trk_sleep', TrackerKind.duration, 'sleep', 'unit_hours', 8),
    _SeedTracker('trk_steps', TrackerKind.number, 'steps', 'unit_steps', 10000),
    _SeedTracker('trk_read', TrackerKind.habit, 'book', null, 1),
    _SeedTracker('trk_workout', TrackerKind.habit, 'pulse', null, 1),
    _SeedTracker('trk_no_social', TrackerKind.habit, 'no_phone', null, 1),
  ];

  /// Досеивает недостающие встроенные элементы. Безопасно вызывать при каждом
  /// запуске: то, что человек удалил, остаётся удалённым (тумбстоун CRDT —
  /// строка есть, но `is_deleted = 1`, поэтому «не вернётся из мёртвых»).
  static Future<void> ensure(SqlCrdt crdt) async {
    await _ensureTable(
      crdt,
      table: 'emotions',
      keys: emotions.map((e) => e.key),
      insert: (key) {
        final s = emotions.firstWhere((e) => e.key == key);
        final i = emotions.indexOf(s);
        return (
          'INSERT INTO emotions (id, kind, color, icon, sort, builtin, enc) '
              'VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
          <Object?>[s.key, s.kind.name, null, s.icon, i, s.key, null],
        );
      },
    );
    await _ensureTable(
      crdt,
      table: 'activities',
      keys: activities.map((e) => e.key),
      insert: (key) {
        final s = activities.firstWhere((e) => e.key == key);
        final i = activities.indexOf(s);
        return (
          'INSERT INTO activities (id, category, color, icon, sort, builtin, '
              'enc) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)',
          <Object?>[s.key, s.category.name, null, s.icon, i, s.key, null],
        );
      },
    );
    await _ensureTable(
      crdt,
      table: 'trackers',
      keys: trackers.map((e) => e.key),
      insert: (key) {
        final s = trackers.firstWhere((e) => e.key == key);
        final i = trackers.indexOf(s);
        return (
          'INSERT INTO trackers (id, kind, unit, goal, icon, color, sort, '
              'builtin, enc) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)',
          <Object?>[
            s.key,
            s.kind.name,
            s.unit,
            s.goal,
            s.icon,
            null,
            i,
            s.key,
            null,
          ],
        );
      },
    );
  }

  static Future<void> _ensureTable(
    SqlCrdt crdt, {
    required String table,
    required Iterable<String> keys,
    required (String, List<Object?>) Function(String key) insert,
  }) async {
    // Берём и удалённые тоже: раз человек стёр «кофе», досеивать его не надо.
    final rows = await crdt.query('SELECT id FROM $table');
    final known = rows.map((r) => r['id'] as String).toSet();
    for (final key in keys) {
      if (known.contains(key)) continue;
      final (sql, args) = insert(key);
      await crdt.execute(sql, args);
    }
  }
}

class _SeedEmotion {
  final String key;
  final EmotionKind kind;
  final String icon;
  const _SeedEmotion(this.key, this.kind, this.icon);
}

class _SeedActivity {
  final String key;
  final ActivityCategory category;
  final String icon;
  const _SeedActivity(this.key, this.category, this.icon);
}

class _SeedTracker {
  final String key;
  final TrackerKind kind;
  final String icon;
  final String? unit;
  final double goal;
  const _SeedTracker(this.key, this.kind, this.icon, this.unit, this.goal);
}
