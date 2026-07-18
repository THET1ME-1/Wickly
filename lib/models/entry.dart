import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Чем накрыта шапка записи.
enum CoverMode {
  /// Без баннера: сразу заголовок, дата и текст.
  none,

  /// Первое наглядное вложение записи.
  auto,

  /// Снимок, подобранный по теме записи.
  web,

  /// Свой снимок, обрезанный под шапку. Лежит рядом с вложениями, но в
  /// галерее записи не показывается: он часть оформления, а не память.
  own;

  static CoverMode parse(String? raw) => CoverMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => CoverMode.auto,
      );

  /// Шапку держит конкретное вложение, а не первое попавшееся.
  bool get isPinned => this == CoverMode.web || this == CoverMode.own;
}

/// Дневник (журнал): у пользователя их может быть несколько — «Личное»,
/// «Путешествия» и т.д. Хранится в таблице `journals`.
///
/// Имя лежит зашифрованным (`enc`), поэтому [name] заполняется репозиторием
/// после расшифровки. Плейнтекстом остаются только обложка, цвет и порядок.
class Journal {
  final String id;
  final String name;
  final int? color; // ARGB акцента обложки (nullable)
  final String? icon; // ключ иконки
  final String? cover; // ключ градиента обложки
  final bool locked; // дневник под отдельным паролем
  final int sort;
  final DateTime createdAt;

  const Journal({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.cover,
    this.locked = false,
    this.sort = 0,
    required this.createdAt,
  });

  factory Journal.create({
    required String name,
    int? color,
    String? icon,
    String? cover,
    bool locked = false,
    int sort = 0,
  }) =>
      Journal(
        id: _uuid.v4(),
        name: name,
        color: color,
        icon: icon,
        cover: cover,
        locked: locked,
        sort: sort,
        createdAt: DateTime.now(),
      );

  /// Структурные колонки (без приватного текста).
  Map<String, Object?> toRowColumns() => {
        'id': id,
        // Пустая строка вместо NULL — в базах с v1 у колонки осталось NOT NULL.
        'name': '',
        'color': color,
        'icon': icon,
        'cover': cover,
        'locked': locked ? 1 : 0,
        'sort': sort,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  Map<String, Object?> toPayload() => {'name': name};

  factory Journal.fromStorage(
    Map<String, Object?> row,
    Map<String, Object?> payload,
  ) =>
      Journal(
        id: row['id'] as String,
        // Приоритет у расшифрованного имени; строки из v1 читаются из `name`.
        name: (payload['name'] as String?) ?? (row['name'] as String?) ?? '',
        color: row['color'] as int?,
        icon: row['icon'] as String?,
        cover: row['cover'] as String?,
        locked: ((row['locked'] as int?) ?? 0) == 1,
        sort: (row['sort'] as int?) ?? 0,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch((row['created_at'] as int?) ?? 0),
      );

  Journal copyWith({
    String? name,
    int? color,
    String? icon,
    String? cover,
    bool? locked,
    int? sort,
  }) =>
      Journal(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        icon: icon ?? this.icon,
        cover: cover ?? this.cover,
        locked: locked ?? this.locked,
        sort: sort ?? this.sort,
        createdAt: createdAt,
      );
}

/// Одна запись дневника. Запись-центричная модель под CRDT-синк: стабильный
/// [id] (UUID), а метаданные слияния (`hlc`, `modified`, `is_deleted`) добавляет
/// сам CRDT-слой поверх таблицы `entries`.
class Entry {
  final String id;
  final String journalId;
  final String? title;

  /// Тело записи — текст с лёгкой Markdown-разметкой (см. `markdown_lite.dart`):
  /// заголовки, жирный/курсив, списки, чеклисты `- [ ]`, цитаты `>`.
  final String? body;

  /// О каком моменте запись (для сортировки в ленте/календаре) — можно задать
  /// задним числом.
  final DateTime entryDate;
  final DateTime createdAt;

  /// Настроение 1..5 (nullable).
  final int? mood;

  /// Авто-контекст момента.
  final String? weather; // человеческое описание: «ясно»
  final int? weatherCode; // код Open-Meteo (иконка)
  final double? temp; // °C
  final String? place; // человеческое название места
  final double? lat;
  final double? lon;
  final int? steps; // активность за день, если отдало здоровье
  final String? nowPlaying; // что играло в момент записи

  /// Обложка — id медиа из этой же записи.
  final String? coverMediaId;

  /// Что показывать шапкой записи: ничего, первое фото или подобранный снимок.
  ///
  /// Отдельно от [coverMediaId], потому что «выключить обложку» и «обложки ещё
  /// нет» — разные вещи: без этого поля выключенный баннер возвращался бы сам,
  /// стоило добавить в запись фотографию.
  final CoverMode coverMode;

  final int wordCount;

  /// Сколько времени человек писал запись (мс) — «время на запись».
  final int writeMs;

  /// Ключ журнальной подсказки, если запись начата с неё.
  final String? promptKey;

  /// Когда появилась каждая тема записи (unix ms), по порядку блоков.
  ///
  /// Живёт в шифрованном payload, а не в самом тексте: разметка уходит в
  /// экспорт и синхронизацию, и служебные метки там были бы мусором. Список
  /// может разойтись с числом блоков — тогда недостающим временем считается
  /// время самой записи.
  final List<int> blockTimes;

  final bool favorite;
  final bool pinned;
  final bool hidden; // скрытая запись: видна только после разблокировки
  final bool draft; // черновик: автосохранён, но не завершён

  const Entry({
    required this.id,
    required this.journalId,
    this.title,
    this.body,
    required this.entryDate,
    required this.createdAt,
    this.mood,
    this.weather,
    this.weatherCode,
    this.temp,
    this.place,
    this.lat,
    this.lon,
    this.steps,
    this.nowPlaying,
    this.coverMediaId,
    this.coverMode = CoverMode.auto,
    this.wordCount = 0,
    this.writeMs = 0,
    this.promptKey,
    this.blockTimes = const [],
    this.favorite = false,
    this.pinned = false,
    this.hidden = false,
    this.draft = false,
  });

  /// Новая запись с сгенерированным [id] и текущим временем.
  factory Entry.create({
    required String journalId,
    String? title,
    String? body,
    DateTime? entryDate,
    int? mood,
    String? promptKey,
    bool draft = false,
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
      promptKey: promptKey,
      draft: draft,
    );
  }

  /// Есть ли у записи привязка к месту (для карты).
  bool get hasPlace => lat != null && lon != null;

  /// Плейнтекст-колонки таблицы `entries` (для запросов/сортировки —
  /// не содержат приватного: только id, дневник, даты, флаги).
  Map<String, Object?> toRowColumns() => {
        'id': id,
        'journal_id': journalId,
        'entry_date': entryDate.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
        'favorite': favorite ? 1 : 0,
        'pinned': pinned ? 1 : 0,
        'hidden': hidden ? 1 : 0,
        'draft': draft ? 1 : 0,
      };

  /// Приватные поля — шифруются (AES-GCM) в колонку `enc`.
  Map<String, Object?> toPayload() => {
        'title': title,
        'body': body,
        'mood': mood,
        'weather': weather,
        'weatherCode': weatherCode,
        'temp': temp,
        'place': place,
        'lat': lat,
        'lon': lon,
        'steps': steps,
        'nowPlaying': nowPlaying,
        'coverMediaId': coverMediaId,
        'coverMode': coverMode.name,
        'wordCount': wordCount,
        'writeMs': writeMs,
        'promptKey': promptKey,
        'blockTimes': blockTimes,
      };

  /// Собирает запись из плейнтекст-строки и расшифрованного payload.
  factory Entry.fromStorage(
    Map<String, Object?> row,
    Map<String, Object?> payload,
  ) =>
      Entry(
        id: row['id'] as String,
        journalId: row['journal_id'] as String,
        entryDate: DateTime.fromMillisecondsSinceEpoch(
            (row['entry_date'] as int?) ?? 0),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (row['created_at'] as int?) ?? 0),
        favorite: ((row['favorite'] as int?) ?? 0) == 1,
        pinned: ((row['pinned'] as int?) ?? 0) == 1,
        hidden: ((row['hidden'] as int?) ?? 0) == 1,
        draft: ((row['draft'] as int?) ?? 0) == 1,
        title: payload['title'] as String?,
        body: payload['body'] as String?,
        mood: payload['mood'] as int?,
        weather: payload['weather'] as String?,
        weatherCode: payload['weatherCode'] as int?,
        temp: (payload['temp'] as num?)?.toDouble(),
        place: payload['place'] as String?,
        lat: (payload['lat'] as num?)?.toDouble(),
        lon: (payload['lon'] as num?)?.toDouble(),
        steps: payload['steps'] as int?,
        nowPlaying: payload['nowPlaying'] as String?,
        coverMediaId: payload['coverMediaId'] as String?,
        coverMode: CoverMode.parse(payload['coverMode'] as String?),
        wordCount: (payload['wordCount'] as int?) ?? 0,
        writeMs: (payload['writeMs'] as int?) ?? 0,
        promptKey: payload['promptKey'] as String?,
        blockTimes: [
          for (final v in (payload['blockTimes'] as List?) ?? const [])
            if (v is num) v.toInt(),
        ],
      );

  /// `null` в аргументе означает «не трогать»; чтобы стереть значение,
  /// используем [clearMood] / [clearPlace] / [clearCover].
  Entry copyWith({
    String? journalId,
    String? title,
    String? body,
    DateTime? entryDate,
    int? mood,
    String? weather,
    int? weatherCode,
    double? temp,
    String? place,
    double? lat,
    double? lon,
    int? steps,
    String? nowPlaying,
    String? coverMediaId,
    CoverMode? coverMode,
    int? wordCount,
    int? writeMs,
    String? promptKey,
    List<int>? blockTimes,
    bool? favorite,
    bool? pinned,
    bool? hidden,
    bool? draft,
    bool clearMood = false,
    bool clearPlace = false,
    bool clearCover = false,
  }) =>
      Entry(
        id: id,
        journalId: journalId ?? this.journalId,
        title: title ?? this.title,
        body: body ?? this.body,
        entryDate: entryDate ?? this.entryDate,
        createdAt: createdAt,
        mood: clearMood ? null : (mood ?? this.mood),
        weather: clearPlace ? null : (weather ?? this.weather),
        weatherCode: clearPlace ? null : (weatherCode ?? this.weatherCode),
        temp: clearPlace ? null : (temp ?? this.temp),
        place: clearPlace ? null : (place ?? this.place),
        lat: clearPlace ? null : (lat ?? this.lat),
        lon: clearPlace ? null : (lon ?? this.lon),
        steps: steps ?? this.steps,
        nowPlaying: nowPlaying ?? this.nowPlaying,
        coverMediaId: clearCover ? null : (coverMediaId ?? this.coverMediaId),
        coverMode: coverMode ?? this.coverMode,
        wordCount: wordCount ?? this.wordCount,
        writeMs: writeMs ?? this.writeMs,
        promptKey: promptKey ?? this.promptKey,
        blockTimes: blockTimes ?? this.blockTimes,
        favorite: favorite ?? this.favorite,
        pinned: pinned ?? this.pinned,
        hidden: hidden ?? this.hidden,
        draft: draft ?? this.draft,
      );
}
