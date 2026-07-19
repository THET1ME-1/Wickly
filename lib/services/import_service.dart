import 'dart:convert';

import 'package:xml/xml.dart';

/// Вид вложения в разобранном бэкапе.
enum ImportMediaKind { photo, video, audio }

/// Ссылка на файл вложения внутри архива/папки бэкапа. Байты подтянет
/// [ImportRunner] по [sourceName], когда будет писать в базу.
class ImportedMedia {
  final ImportMediaKind kind;

  /// Имя файла в источнике: внутри zip — путь в архиве, у StoryPad — имя в
  /// папке `images/`. Пустое имя означает «файл в этом бэкапе не приложен»
  /// (Diaro хранит фото отдельно от XML).
  final String sourceName;

  const ImportedMedia({required this.kind, required this.sourceName});
}

/// Одна запись из чужого дневника, приведённая к полям Wickly.
class ImportedEntry {
  final String? title;
  final String? body;
  final DateTime date;

  /// Настроение в шкале Wickly (1 — плохо … 5 — отлично) или null.
  final int? mood;
  final List<String> tags;
  final String? place;
  final double? lat;
  final double? lon;
  final String? weather;
  final double? temp;
  final bool favorite;
  final bool pinned;
  final List<ImportedMedia> media;

  const ImportedEntry({
    this.title,
    this.body,
    required this.date,
    this.mood,
    this.tags = const [],
    this.place,
    this.lat,
    this.lon,
    this.weather,
    this.temp,
    this.favorite = false,
    this.pinned = false,
    this.media = const [],
  });

  bool get isEmpty =>
      (title == null || title!.trim().isEmpty) &&
      (body == null || body!.trim().isEmpty) &&
      media.isEmpty;
}

/// Дневник (папка) из чужого бэкапа с его записями.
class ImportedJournal {
  final String name;
  final int? color; // ARGB, если формат его хранит
  final List<ImportedEntry> entries;

  const ImportedJournal({
    required this.name,
    this.color,
    this.entries = const [],
  });
}

/// Разобранный бэкап целиком.
class ImportBundle {
  /// Из какого приложения (для экрана и логов).
  final String source;
  final List<ImportedJournal> journals;

  const ImportBundle({required this.source, this.journals = const []});

  int get entryCount =>
      journals.fold(0, (sum, j) => sum + j.entries.length);
  int get mediaCount => journals.fold(
      0, (sum, j) => sum + j.entries.fold(0, (s, e) => s + e.media.length));
  bool get isEmpty => entryCount == 0;
}

/// Разбор бэкапов в [ImportBundle]. Без Flutter — чистые функции над текстом.
class ImportService {
  const ImportService._();

  // ------------------------------- Diaro -------------------------------

  /// Diaro: XML `DiaroBackup.xml` из zip-бэкапа. Таблицы `diaro_folders`,
  /// `diaro_tags`, `diaro_entries`, `diaro_attachments`, `diaro_locations`.
  /// Фото Diaro держит отдельно от XML — в авто-бэкапе их нет, поэтому у
  /// вложений остаётся только имя файла (импортёр приложит их, если найдёт).
  static ImportBundle parseDiaro(String xmlText) {
    final doc = XmlDocument.parse(xmlText);

    Map<String, XmlElement> tables = {
      for (final t in doc.findAllElements('table'))
        (t.getAttribute('name') ?? ''): t,
    };

    List<Map<String, String>> rows(String table) {
      final el = tables[table];
      if (el == null) return const [];
      return [
        for (final r in el.findElements('r'))
          {
            for (final f in r.childElements) f.name.local: f.innerText,
          },
      ];
    }

    final folders = {
      for (final r in rows('diaro_folders'))
        if ((r['uid'] ?? '').isNotEmpty) r['uid']!: r,
    };
    final tags = {
      for (final r in rows('diaro_tags'))
        if ((r['uid'] ?? '').isNotEmpty) r['uid']!: (r['title'] ?? '').trim(),
    };
    final locations = {
      for (final r in rows('diaro_locations'))
        if ((r['uid'] ?? '').isNotEmpty) r['uid']!: r,
    };

    // Вложения по записи.
    final attachments = <String, List<ImportedMedia>>{};
    for (final r in rows('diaro_attachments')) {
      final entryUid = r['entry_uid'] ?? '';
      final filename = (r['filename'] ?? '').trim();
      if (entryUid.isEmpty || filename.isEmpty) continue;
      (attachments[entryUid] ??= []).add(ImportedMedia(
        kind: _diaroMediaKind(r['type']),
        sourceName: filename,
      ));
    }

    // Записи раскладываем по папкам.
    final byFolder = <String, List<ImportedEntry>>{};
    for (final r in rows('diaro_entries')) {
      final ms = int.tryParse(r['date'] ?? '');
      if (ms == null) continue;
      final folderUid = r['folder_uid'] ?? '';
      final loc = locations[r['location_uid'] ?? ''];

      final entry = ImportedEntry(
        title: _nullIfEmpty(r['title']),
        body: _nullIfEmpty(r['text']),
        date: DateTime.fromMillisecondsSinceEpoch(ms),
        mood: _diaroMood(r['mood']),
        tags: _diaroTags(r['tags'], tags),
        place: loc == null ? null : _diaroPlace(loc),
        lat: loc == null ? null : double.tryParse(loc['lat'] ?? ''),
        lon: loc == null ? null : double.tryParse(loc['lng'] ?? ''),
        weather: _nullIfEmpty(r['weather_description']),
        temp: double.tryParse(r['weather_temperature'] ?? ''),
        media: attachments[r['uid'] ?? ''] ?? const [],
      );
      (byFolder[folderUid] ??= []).add(entry);
    }

    final journals = <ImportedJournal>[];
    byFolder.forEach((folderUid, entries) {
      final folder = folders[folderUid];
      journals.add(ImportedJournal(
        name: (folder?['title'] ?? '').trim().isNotEmpty
            ? folder!['title']!.trim()
            : 'Diaro',
        color: _hexColor(folder?['color']),
        entries: entries,
      ));
    });

    return ImportBundle(source: 'Diaro', journals: journals);
  }

  /// Diaro: настроение 1..5, где 1 — лучшее. У Wickly наоборот (5 — отлично),
  /// поэтому переворачиваем. 0/пусто — настроения не было.
  static int? _diaroMood(String? raw) {
    final v = int.tryParse(raw ?? '');
    if (v == null || v < 1 || v > 5) return null;
    return 6 - v;
  }

  static List<String> _diaroTags(String? csv, Map<String, String> byUid) {
    if (csv == null || csv.isEmpty) return const [];
    return [
      for (final uid in csv.split(','))
        if (byUid[uid.trim()] != null && byUid[uid.trim()]!.isNotEmpty)
          byUid[uid.trim()]!,
    ];
  }

  static String? _diaroPlace(Map<String, String> loc) {
    final title = (loc['title'] ?? '').trim();
    if (title.isNotEmpty) return title;
    final address = (loc['address'] ?? '').trim();
    return address.isEmpty ? null : address;
  }

  static ImportMediaKind _diaroMediaKind(String? type) => switch (type) {
        'video' => ImportMediaKind.video,
        'audio' => ImportMediaKind.audio,
        _ => ImportMediaKind.photo,
      };

  // ------------------------------ StoryPad ------------------------------

  /// StoryPad: JSON-бэкап. `tables.stories` — записи, `tables.tags` — теги.
  /// Фото лежат отдельно в папке `images/<assetId>.<ext>`; связь — через
  /// `story.assets` (список id) и `tables.assets` (тип каждого).
  static ImportBundle parseStoryPad(String jsonText) {
    final root = jsonDecode(jsonText);
    if (root is! Map) return const ImportBundle(source: 'StoryPad');
    final tables = root['tables'];
    if (tables is! Map) return const ImportBundle(source: 'StoryPad');

    List list(String key) {
      final v = tables[key];
      return v is List ? v : const [];
    }

    final tagTitles = <String, String>{
      for (final t in list('tags'))
        if (t is Map && t['id'] != null)
          '${t['id']}': _cleanTag('${t['title'] ?? ''}'),
    };
    // Тип ассета по id: фото/аудио.
    final assetKind = <String, ImportMediaKind>{
      for (final a in list('assets'))
        if (a is Map && a['id'] != null)
          '${a['id']}': _storyPadAssetKind('${a['type'] ?? ''}'),
    };
    // Расширение файла из original_source: images/<id>.<ext>.
    final assetExt = <String, String>{
      for (final a in list('assets'))
        if (a is Map && a['id'] != null)
          '${a['id']}': _extOfPath('${a['original_source'] ?? ''}'),
    };

    final entries = <ImportedEntry>[];
    for (final s in list('stories')) {
      if (s is! Map) continue;
      // В корзину/удалённое не тянем.
      if ('${s['moved_to_bin_at']}' != 'None' &&
          s['moved_to_bin_at'] != null) {
        continue;
      }
      if ('${s['permanently_deleted_at']}' != 'None' &&
          s['permanently_deleted_at'] != null) {
        continue;
      }

      final date = _storyPadDate(s);
      if (date == null) continue;

      // latest_content — вложенный объект {title, plain_text, rich_pages}.
      final content = s['latest_content'];
      final title = content is Map ? content['title'] as String? : null;
      final body = content is Map ? content['plain_text'] as String? : null;
      entries.add(ImportedEntry(
        title: _nullIfEmpty(title),
        body: _nullIfEmpty(body),
        date: date,
        mood: _storyPadMood('${s['feeling']}'),
        tags: _storyPadTags(s['tags'], tagTitles),
        favorite: '${s['starred']}'.toLowerCase() == 'true',
        pinned: '${s['pinned']}'.toLowerCase() == 'true',
        media: _storyPadMedia(s['assets'], assetKind, assetExt),
      ));
    }

    return ImportBundle(
      source: 'StoryPad',
      journals: [
        if (entries.isNotEmpty) ImportedJournal(name: 'StoryPad', entries: entries),
      ],
    );
  }

  static DateTime? _storyPadDate(Map s) {
    final y = _int(s['year']);
    final mo = _int(s['month']);
    final d = _int(s['day']);
    if (y == null || mo == null || d == null) return null;
    return DateTime(
      y,
      mo,
      d,
      _int(s['hour']) ?? 0,
      _int(s['minute']) ?? 0,
      _int(s['second']) ?? 0,
    );
  }

  static List<String> _storyPadTags(Object? raw, Map<String, String> titles) {
    // tags приходит списком id ([1, 2]) или его строковым видом ("['1','2']").
    final ids = <String>[];
    if (raw is List) {
      ids.addAll(raw.map((e) => '$e'));
    } else if (raw is String) {
      for (final m in RegExp(r'\d+').allMatches(raw)) {
        ids.add(m.group(0)!);
      }
    }
    return [
      for (final id in ids)
        if ((titles[id] ?? '').isNotEmpty) titles[id]!,
    ];
  }

  static List<ImportedMedia> _storyPadMedia(
    Object? raw,
    Map<String, ImportMediaKind> kinds,
    Map<String, String> exts,
  ) {
    final ids = <String>[];
    if (raw is List) {
      ids.addAll(raw.map((e) => '$e'));
    } else if (raw is String) {
      for (final m in RegExp(r'\d+').allMatches(raw)) {
        ids.add(m.group(0)!);
      }
    }
    final out = <ImportedMedia>[];
    for (final id in ids) {
      final ext = exts[id] ?? 'jpg';
      out.add(ImportedMedia(
        kind: kinds[id] ?? ImportMediaKind.photo,
        sourceName: '$id.$ext',
      ));
    }
    return out;
  }

  static ImportMediaKind _storyPadAssetKind(String type) => switch (type) {
        'audio' => ImportMediaKind.audio,
        'video' => ImportMediaKind.video,
        _ => ImportMediaKind.photo,
      };

  /// StoryPad хранит эмодзи-настроение именем; сводим к шкале 1..5.
  static int? _storyPadMood(String feeling) {
    const map = {
      // 1 — плохо
      'crying': 1, 'disappointed': 1, 'pouting': 1, 'worry': 1,
      'head_bandage': 1, 'drooling': 1,
      // 2 — так себе
      'confused': 2, 'nervousness': 2, 'dizzy': 2, 'speechlessness': 2,
      'rolling_eyes': 2, 'sleeping': 2,
      // 3 — нейтрально
      'neutral': 3, 'expressionless': 3, 'serious': 3, 'monocle': 3,
      'nerd': 3, 'zany': 3,
      // 4 — хорошо
      'smiling_halo': 4, 'positive_feelings': 4, 'cheerfulness': 4,
      'savoring_food': 4, 'something_cool': 4, 'grinning_sweat': 4,
      // 5 — отлично
      'beaming': 5, 'excited': 5, 'in_love': 5, 'crazy': 5, 'blowing': 5,
      'getting_rich': 5,
    };
    return map[feeling];
  }

  // ------------------------------ Общее ------------------------------

  /// Убирает ведущий эмодзи из имени тега StoryPad («🧠 Мысли» → «Мысли»).
  static String _cleanTag(String title) {
    final t = title.trim();
    // Первый «токен» — эмодзи? Отрезаем всё до первого пробела, если там нет
    // букв/цифр.
    final space = t.indexOf(' ');
    if (space > 0) {
      final head = t.substring(0, space);
      if (!RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(head)) {
        return t.substring(space + 1).trim();
      }
    }
    return t;
  }

  static String _extOfPath(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'jpg';
    final ext = name.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext) ? ext : 'jpg';
  }

  static int? _hexColor(String? hex) {
    if (hex == null) return null;
    final h = hex.replaceAll('#', '').trim();
    if (h.length != 6) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : 0xFF000000 | v;
  }

  static int? _int(Object? v) =>
      v is int ? v : int.tryParse('${v ?? ''}');

  static String? _nullIfEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
