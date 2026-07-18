import '../data/catalog_repository.dart';
import '../data/media_repository.dart';
import '../models/catalog.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../widgets/entry_card.dart';

/// Собирает записи вместе с обложками, счётчиками вложений и тегами.
///
/// Одним заходом на весь список, а не по запросу на карточку: иначе лента на
/// сотне записей делает сотни обращений к базе на каждый её тик.
class FeedService {
  const FeedService._();

  static Future<List<EntryCardItem>> decorate(List<Entry> entries) async {
    if (entries.isEmpty) return const [];

    final media = await MediaRepository.instance.all();
    final tagLinks =
        await CatalogRepository.instance.allLinks('entry_tags', 'tag_id');
    final tags = {for (final t in await CatalogRepository.instance.tags()) t.id: t};

    final byEntry = <String, List<Media>>{};
    for (final m in media) {
      (byEntry[m.entryId] ??= []).add(m);
    }

    return [
      for (final e in entries)
        EntryCardItem(
          entry: e,
          cover: _coverOf(e, byEntry[e.id]),
          mediaCount: byEntry[e.id]?.length ?? 0,
          tags: [
            for (final id in tagLinks[e.id] ?? const <String>[])
              if (tags[id] != null) tags[id]!.name,
          ],
        ),
    ];
  }

  /// Обложка записи: выбранная человеком, иначе первое наглядное вложение.
  /// Аудио обложкой не становится — карточке нечего показать.
  static Media? _coverOf(Entry e, List<Media>? media) {
    if (media == null || media.isEmpty) return null;
    final sorted = [...media]..sort((a, b) => a.sort.compareTo(b.sort));
    if (e.coverMediaId != null) {
      for (final m in sorted) {
        if (m.id == e.coverMediaId) return m;
      }
    }
    for (final m in sorted) {
      if (m.isVisual || m.kind == MediaKind.video) return m;
    }
    return null;
  }

  /// Картина последних семи дней: писал или нет (свежий день — последний).
  static List<bool> lastWeek(List<Entry> entries, DateTime now) {
    final days = {
      for (final e in entries) TrackerLog.dayKey(e.entryDate),
    };
    return [
      for (var i = 6; i >= 0; i--)
        days.contains(
            TrackerLog.dayKey(now.subtract(Duration(days: i)))),
    ];
  }
}
