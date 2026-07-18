import '../data/catalog_repository.dart';
import '../data/media_repository.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../widgets/markdown_lite.dart';

/// Чем ограничен поиск.
class SearchFilters {
  final int? mood;
  final String? place;
  final bool withPhoto;
  final int? year;
  final String? tagId;
  final String? journalId;

  /// Только избранные. Флаг у записи был, а добраться до отмеченного было
  /// нечем: ни экрана, ни фильтра.
  final bool favorite;

  const SearchFilters({
    this.mood,
    this.place,
    this.withPhoto = false,
    this.year,
    this.tagId,
    this.journalId,
    this.favorite = false,
  });

  bool get isEmpty =>
      mood == null &&
      place == null &&
      !withPhoto &&
      year == null &&
      tagId == null &&
      journalId == null &&
      !favorite;

  SearchFilters copyWith({
    int? mood,
    String? place,
    bool? withPhoto,
    int? year,
    String? tagId,
    String? journalId,
    bool? favorite,
    bool clearMood = false,
    bool clearPlace = false,
    bool clearYear = false,
    bool clearTag = false,
  }) =>
      SearchFilters(
        mood: clearMood ? null : (mood ?? this.mood),
        place: clearPlace ? null : (place ?? this.place),
        withPhoto: withPhoto ?? this.withPhoto,
        year: clearYear ? null : (year ?? this.year),
        tagId: clearTag ? null : (tagId ?? this.tagId),
        journalId: journalId ?? this.journalId,
        favorite: favorite ?? this.favorite,
      );
}

/// Найденная запись вместе с куском текста, где нашлось совпадение.
class EntryHit {
  final Entry entry;

  /// Отрывок вокруг совпадения.
  final String snippet;

  /// Где в [snippet] лежит найденное — чтобы подсветить.
  final int matchStart;
  final int matchLength;

  const EntryHit({
    required this.entry,
    required this.snippet,
    this.matchStart = -1,
    this.matchLength = 0,
  });
}

/// Найденный текст на фотографии.
class PhotoHit {
  final Media media;
  final Entry entry;
  final String snippet;
  final int matchStart;
  final int matchLength;

  const PhotoHit({
    required this.media,
    required this.entry,
    required this.snippet,
    this.matchStart = -1,
    this.matchLength = 0,
  });
}

/// Что нашлось.
class SearchResult {
  final List<EntryHit> entries;
  final List<PhotoHit> photos;

  const SearchResult({this.entries = const [], this.photos = const []});

  bool get isEmpty => entries.isEmpty && photos.isEmpty;
  int get total => entries.length + photos.length;
}

/// Поиск по дневнику: текст, метаданные и распознанный текст на фото.
///
/// Полнотекстового индекса нет намеренно: записи лежат зашифрованными, а FTS5
/// по шифртексту бесполезен. Дневник за десять лет — это тысячи записей, и
/// проход по ним в памяти занимает миллисекунды, зато содержимое не приходится
/// хранить открытым ради скорости.
class SearchService {
  const SearchService._();

  static Future<SearchResult> search(
    List<Entry> entries,
    String query, {
    SearchFilters filters = const SearchFilters(),
  }) async {
    final q = query.trim().toLowerCase();
    final needFilters = !filters.isEmpty;
    if (q.isEmpty && !needFilters) return const SearchResult();

    final mediaByEntry = <String, List<Media>>{};
    for (final m in await MediaRepository.instance.all()) {
      (mediaByEntry[m.entryId] ??= []).add(m);
    }
    final tagLinks =
        await CatalogRepository.instance.allLinks('entry_tags', 'tag_id');

    final hits = <EntryHit>[];
    final photos = <PhotoHit>[];

    for (final e in entries) {
      if (!_passes(e, filters, mediaByEntry[e.id], tagLinks[e.id])) continue;

      if (q.isEmpty) {
        hits.add(EntryHit(entry: e, snippet: _preview(e)));
        continue;
      }

      // Поля перебираем по отдельности: если совпало в тексте, отрывок должен
      // быть из текста, а не начинаться с заголовка, который и так на виду.
      final body = MarkdownLite.strip(e.body);
      final inBody = body.toLowerCase().indexOf(q);
      if (inBody >= 0) {
        hits.add(_hit(e, body, inBody, q.length));
      } else if ((e.title ?? '').toLowerCase().contains(q)) {
        hits.add(EntryHit(entry: e, snippet: body.isEmpty ? e.title! : body));
      } else if ((e.place ?? '').toLowerCase().contains(q)) {
        hits.add(EntryHit(entry: e, snippet: e.place!));
      }

      // Текст на фотографиях ищем отдельным списком: в макете это своя секция,
      // и находка «на фото» ценится иначе, чем находка в тексте.
      for (final m in mediaByEntry[e.id] ?? const <Media>[]) {
        final ocr = m.ocr;
        if (ocr == null || ocr.isEmpty) continue;
        final ocrAt = ocr.toLowerCase().indexOf(q);
        if (ocrAt < 0) continue;
        final cut = _cut(ocr, ocrAt, q.length);
        photos.add(PhotoHit(
          media: m,
          entry: e,
          snippet: cut.$1,
          matchStart: cut.$2,
          matchLength: q.length,
        ));
      }
    }

    return SearchResult(entries: hits, photos: photos);
  }

  static bool _passes(
    Entry e,
    SearchFilters f,
    List<Media>? media,
    List<String>? tags,
  ) {
    if (f.favorite && !e.favorite) return false;
    if (f.mood != null && e.mood != f.mood) return false;
    if (f.place != null &&
        (e.place ?? '').toLowerCase() != f.place!.toLowerCase()) {
      return false;
    }
    if (f.year != null && e.entryDate.year != f.year) return false;
    if (f.journalId != null && e.journalId != f.journalId) return false;
    if (f.tagId != null && !(tags ?? const []).contains(f.tagId)) return false;
    if (f.withPhoto) {
      final hasVisual =
          (media ?? const <Media>[]).any((m) => m.isVisual || m.kind == MediaKind.video);
      if (!hasVisual) return false;
    }
    return true;
  }

  static EntryHit _hit(Entry e, String haystack, int at, int length) {
    final cut = _cut(haystack, at, length);
    return EntryHit(
      entry: e,
      snippet: cut.$1,
      matchStart: cut.$2,
      matchLength: length,
    );
  }

  /// Вырезает отрывок вокруг совпадения и говорит, где оно внутри отрывка.
  static (String, int) _cut(String source, int at, int length) {
    const before = 32;
    const total = 120;
    var start = at - before;
    if (start < 0) start = 0;
    var end = start + total;
    if (end > source.length) end = source.length;

    var snippet = source.substring(start, end).trim();
    final prefix = start > 0 ? '…' : '';
    final suffix = end < source.length ? '…' : '';
    final shift = at - start + prefix.length - (source.substring(start, end).length - source.substring(start, end).trimLeft().length);
    snippet = '$prefix$snippet$suffix';
    return (snippet, shift.clamp(0, snippet.length));
  }

  static String _preview(Entry e) {
    final title = e.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return MarkdownLite.strip(e.body);
  }
}
