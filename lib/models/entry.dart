import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Дневник (журнал): у пользователя их может быть несколько — «Личное»,
/// «Путешествия» и т.д. Хранится в таблице `journals`.
class Journal {
  final String id;
  final String name;
  final int? color; // ARGB seed обложки (nullable)
  final String? icon; // ключ иконки (nullable)
  final int sort;
  final DateTime createdAt;

  const Journal({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.sort = 0,
    required this.createdAt,
  });

  factory Journal.create({
    required String name,
    int? color,
    String? icon,
    int sort = 0,
  }) =>
      Journal(
        id: _uuid.v4(),
        name: name,
        color: color,
        icon: icon,
        sort: sort,
        createdAt: DateTime.now(),
      );

  factory Journal.fromRow(Map<String, Object?> r) => Journal(
        id: r['id'] as String,
        name: r['name'] as String,
        color: r['color'] as int?,
        icon: r['icon'] as String?,
        sort: (r['sort'] as int?) ?? 0,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((r['created_at'] as int?) ?? 0),
      );

  Map<String, Object?> toColumns() => {
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
        'sort': sort,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

/// Одна запись дневника. Запись-центричная модель под CRDT-синк: стабильный
/// [id] (UUID), а метаданные слияния (`hlc`, `modified`, `is_deleted`) добавляет
/// сам CRDT-слой поверх таблицы `entries`.
class Entry {
  final String id;
  final String journalId;
  final String? title;

  /// Тело записи (позже — размеченный текст: markdown/JSON). Пока простой текст.
  final String? body;

  /// О каком моменте запись (для сортировки в ленте/календаре).
  final DateTime entryDate;
  final DateTime createdAt;

  /// Настроение 1..5 (nullable).
  final int? mood;

  final String? weather;
  final String? place;
  final double? lat;
  final double? lon;
  final bool favorite;

  const Entry({
    required this.id,
    required this.journalId,
    this.title,
    this.body,
    required this.entryDate,
    required this.createdAt,
    this.mood,
    this.weather,
    this.place,
    this.lat,
    this.lon,
    this.favorite = false,
  });

  /// Новая запись с сгенерированным [id] и текущим временем.
  factory Entry.create({
    required String journalId,
    String? title,
    String? body,
    DateTime? entryDate,
    int? mood,
    String? weather,
    String? place,
    double? lat,
    double? lon,
    bool favorite = false,
  }) {
    final now = DateTime.now();
    return Entry(
      id: _uuid.v4(),
      journalId: journalId,
      title: title,
      body: body,
      entryDate: entryDate ?? now,
      createdAt: now,
      mood: mood,
      weather: weather,
      place: place,
      lat: lat,
      lon: lon,
      favorite: favorite,
    );
  }

  factory Entry.fromRow(Map<String, Object?> r) => Entry(
        id: r['id'] as String,
        journalId: r['journal_id'] as String,
        title: r['title'] as String?,
        body: r['body'] as String?,
        entryDate:
            DateTime.fromMillisecondsSinceEpoch((r['entry_date'] as int?) ?? 0),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((r['created_at'] as int?) ?? 0),
        mood: r['mood'] as int?,
        weather: r['weather'] as String?,
        place: r['place'] as String?,
        lat: (r['lat'] as num?)?.toDouble(),
        lon: (r['lon'] as num?)?.toDouble(),
        favorite: ((r['favorite'] as int?) ?? 0) == 1,
      );

  Map<String, Object?> toColumns() => {
        'id': id,
        'journal_id': journalId,
        'title': title,
        'body': body,
        'entry_date': entryDate.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'mood': mood,
        'weather': weather,
        'place': place,
        'lat': lat,
        'lon': lon,
        'favorite': favorite ? 1 : 0,
      };

  Entry copyWith({
    String? journalId,
    String? title,
    String? body,
    DateTime? entryDate,
    int? mood,
    String? weather,
    String? place,
    double? lat,
    double? lon,
    bool? favorite,
  }) =>
      Entry(
        id: id,
        journalId: journalId ?? this.journalId,
        title: title ?? this.title,
        body: body ?? this.body,
        entryDate: entryDate ?? this.entryDate,
        createdAt: createdAt,
        mood: mood ?? this.mood,
        weather: weather ?? this.weather,
        place: place ?? this.place,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        favorite: favorite ?? this.favorite,
      );
}
