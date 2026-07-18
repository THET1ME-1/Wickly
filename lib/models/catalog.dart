import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Эмоция окрашена по тону: приятные и тяжёлые показываются разными группами.
enum EmotionKind {
  pleasant,
  hard;

  static EmotionKind parse(String? s) =>
      s == 'hard' ? EmotionKind.hard : EmotionKind.pleasant;
}

/// Категория действия — четыре группы, как на экране «Что ты делал».
enum ActivityCategory {
  people,
  body,
  home,
  rest;

  static ActivityCategory parse(String? s) => ActivityCategory.values.firstWhere(
        (c) => c.name == s,
        orElse: () => ActivityCategory.rest,
      );
}

/// Что именно считает трекер.
enum TrackerKind {
  /// Число за день: стаканы воды, шаги.
  number,

  /// Часы: сон.
  duration,

  /// Привычка «сделал / не сделал» — недельная сетка точек.
  habit;

  static TrackerKind parse(String? s) => TrackerKind.values.firstWhere(
        (k) => k.name == s,
        orElse: () => TrackerKind.number,
      );
}

/// Общая часть каталожных элементов: у встроенных имя приходит из словаря
/// (переводится на 7 языков), у своих — лежит зашифрованным в `enc`.
mixin CatalogItem {
  String get id;

  /// Имя, заданное человеком. Пустое — значит имя берётся из [builtin].
  String get name;

  /// Ключ встроенного элемента (`emo_calm`, `act_coffee`, …) либо `null`.
  String? get builtin;

  String? get icon;
  int? get color;
  int get sort;

  bool get isCustom => builtin == null;
}

/// Своя или встроенная эмоция («спокойствие», «тревога»).
class Emotion with CatalogItem {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? builtin;
  @override
  final String? icon;
  @override
  final int? color;
  @override
  final int sort;

  final EmotionKind kind;

  const Emotion({
    required this.id,
    required this.name,
    required this.kind,
    this.builtin,
    this.icon,
    this.color,
    this.sort = 0,
  });

  factory Emotion.create({
    required String name,
    required EmotionKind kind,
    String? icon,
    int? color,
    int sort = 0,
  }) =>
      Emotion(
        id: _uuid.v4(),
        name: name,
        kind: kind,
        icon: icon,
        color: color,
        sort: sort,
      );

  Map<String, Object?> toRowColumns() => {
        'id': id,
        'kind': kind.name,
        'color': color,
        'icon': icon,
        'sort': sort,
        'builtin': builtin,
      };

  Map<String, Object?> toPayload() => {'name': name};

  factory Emotion.fromStorage(
    Map<String, Object?> row,
    Map<String, Object?> payload,
  ) =>
      Emotion(
        id: row['id'] as String,
        name: (payload['name'] as String?) ?? '',
        kind: EmotionKind.parse(row['kind'] as String?),
        builtin: row['builtin'] as String?,
        icon: row['icon'] as String?,
        color: row['color'] as int?,
        sort: (row['sort'] as int?) ?? 0,
      );

  Emotion copyWith({
    String? name,
    EmotionKind? kind,
    String? icon,
    int? color,
    int? sort,
  }) =>
      Emotion(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        builtin: builtin,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        sort: sort ?? this.sort,
      );
}

/// Своё или встроенное действие («друзья», «кофе», «тренировка»).
class Activity with CatalogItem {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? builtin;
  @override
  final String? icon;
  @override
  final int? color;
  @override
  final int sort;

  final ActivityCategory category;

  const Activity({
    required this.id,
    required this.name,
    required this.category,
    this.builtin,
    this.icon,
    this.color,
    this.sort = 0,
  });

  factory Activity.create({
    required String name,
    required ActivityCategory category,
    String? icon,
    int? color,
    int sort = 0,
  }) =>
      Activity(
        id: _uuid.v4(),
        name: name,
        category: category,
        icon: icon,
        color: color,
        sort: sort,
      );

  Map<String, Object?> toRowColumns() => {
        'id': id,
        'category': category.name,
        'color': color,
        'icon': icon,
        'sort': sort,
        'builtin': builtin,
      };

  Map<String, Object?> toPayload() => {'name': name};

  factory Activity.fromStorage(
    Map<String, Object?> row,
    Map<String, Object?> payload,
  ) =>
      Activity(
        id: row['id'] as String,
        name: (payload['name'] as String?) ?? '',
        category: ActivityCategory.parse(row['category'] as String?),
        builtin: row['builtin'] as String?,
        icon: row['icon'] as String?,
        color: row['color'] as int?,
        sort: (row['sort'] as int?) ?? 0,
      );

  Activity copyWith({
    String? name,
    ActivityCategory? category,
    String? icon,
    int? color,
    int? sort,
  }) =>
      Activity(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        builtin: builtin,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        sort: sort ?? this.sort,
      );
}

/// Трекер (вода, сон, шаги) или привычка.
class Tracker with CatalogItem {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? builtin;
  @override
  final String? icon;
  @override
  final int? color;
  @override
  final int sort;

  final TrackerKind kind;

  /// Единица измерения — ключ словаря (`unit_glasses`, `unit_hours`) или своё.
  final String? unit;

  /// Дневная цель. Для привычки — всегда 1.
  final double? goal;

  /// В какие дни недели привычка ожидается: биты 0..6, где 0 — понедельник.
  ///
  /// Ноль означает «каждый день» — так же читаются и старые привычки, у
  /// которых поля ещё не было. Пропуск в неожидаемый день не рвёт серию:
  /// «спорт трижды в неделю» не должен выглядеть вечным провалом.
  final int weekdays;

  const Tracker({
    required this.id,
    required this.name,
    required this.kind,
    this.unit,
    this.goal,
    this.builtin,
    this.icon,
    this.color,
    this.sort = 0,
    this.weekdays = 0,
  });

  factory Tracker.create({
    required String name,
    required TrackerKind kind,
    String? unit,
    double? goal,
    String? icon,
    int? color,
    int sort = 0,
    int weekdays = 0,
  }) =>
      Tracker(
        id: _uuid.v4(),
        name: name,
        kind: kind,
        unit: unit,
        goal: goal,
        icon: icon,
        color: color,
        sort: sort,
        weekdays: weekdays,
      );

  Map<String, Object?> toRowColumns() => {
        'id': id,
        'kind': kind.name,
        'unit': unit,
        'goal': goal,
        'icon': icon,
        'color': color,
        'sort': sort,
        'builtin': builtin,
      };

  // Расписание уезжает в шифрованный payload, а не в колонку: добавлять
  // колонку значило бы менять схему у всех, кто уже синхронизируется.
  Map<String, Object?> toPayload() => {'name': name, 'weekdays': weekdays};

  factory Tracker.fromStorage(
    Map<String, Object?> row,
    Map<String, Object?> payload,
  ) =>
      Tracker(
        id: row['id'] as String,
        name: (payload['name'] as String?) ?? '',
        kind: TrackerKind.parse(row['kind'] as String?),
        unit: row['unit'] as String?,
        goal: (row['goal'] as num?)?.toDouble(),
        builtin: row['builtin'] as String?,
        icon: row['icon'] as String?,
        color: row['color'] as int?,
        sort: (row['sort'] as int?) ?? 0,
        weekdays: (payload['weekdays'] as num?)?.toInt() ?? 0,
      );

  /// Ожидается ли привычка в этот день.
  bool expectedOn(DateTime day) =>
      weekdays == 0 || (weekdays & (1 << (day.weekday - 1))) != 0;

  /// Сколько дней в неделю ожидается.
  int get daysPerWeek {
    if (weekdays == 0) return 7;
    var count = 0;
    for (var i = 0; i < 7; i++) {
      if ((weekdays & (1 << i)) != 0) count++;
    }
    return count;
  }

  Tracker copyWith({
    String? name,
    TrackerKind? kind,
    String? unit,
    double? goal,
    String? icon,
    int? color,
    int? sort,
    int? weekdays,
  }) =>
      Tracker(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        unit: unit ?? this.unit,
        goal: goal ?? this.goal,
        builtin: builtin,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        sort: sort ?? this.sort,
        weekdays: weekdays ?? this.weekdays,
      );
}

/// Тег записи. Имя зашифровано, как и всё, что написал человек.
class Tag {
  final String id;
  final String name;
  final DateTime createdAt;

  const Tag({required this.id, required this.name, required this.createdAt});

  factory Tag.create(String name) =>
      Tag(id: _uuid.v4(), name: name, createdAt: DateTime.now());

  Map<String, Object?> toRowColumns() => {
        'id': id,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  Map<String, Object?> toPayload() => {'name': name};

  factory Tag.fromStorage(
    Map<String, Object?> row,
    Map<String, Object?> payload,
  ) =>
      Tag(
        id: row['id'] as String,
        name: (payload['name'] as String?) ?? '',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((row['created_at'] as int?) ?? 0),
      );
}

/// Отметка трекера за конкретный день.
class TrackerLog {
  final String id;
  final String trackerId;

  /// День как целое `yyyymmdd` — сравнимо и сортируемо без часовых поясов.
  final int day;
  final double value;

  const TrackerLog({
    required this.id,
    required this.trackerId,
    required this.day,
    required this.value,
  });

  static int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime dayFromKey(int key) =>
      DateTime(key ~/ 10000, (key ~/ 100) % 100, key % 100);

  factory TrackerLog.fromRow(Map<String, Object?> r) => TrackerLog(
        id: r['id'] as String,
        trackerId: r['tracker_id'] as String,
        day: (r['day'] as int?) ?? 0,
        value: ((r['value'] as num?) ?? 0).toDouble(),
      );
}
