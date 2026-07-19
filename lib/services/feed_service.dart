import '../data/catalog_repository.dart';
import '../data/journal_lock.dart';
import '../data/journal_repository.dart';
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

    // Имя дневника показываем на карточке, только когда дневников больше
    // одного: иначе одинаковая метка на каждой записи — лишний шум.
    final journals = {
      for (final j in await JournalRepository.instance.all()) j.id: j,
    };
    final showJournal = journals.length > 1;

    final byEntry = <String, List<Media>>{};
    for (final m in media) {
      (byEntry[m.entryId] ??= []).add(m);
    }

    return [
      for (final e in entries)
        if (JournalLock.isHidden(e.journalId))
          // Запись запертого дневника: карточка есть, содержимого в ней нет.
          // Вложения не подтягиваем вовсе — блюр закрывает картинку только на
          // экране, а тянуть ради него расшифрованный файл во временный
          // каталог незачем.
          EntryCardItem(
            entry: e,
            locked: true,
            journalName: journals[e.journalId]?.name,
          )
        else
          EntryCardItem(
            entry: e,
            cover: _coverOf(e, byEntry[e.id]),
            mediaCount: byEntry[e.id]?.length ?? 0,
            tags: [
              for (final id in tagLinks[e.id] ?? const <String>[])
                if (tags[id] != null) tags[id]!.name,
            ],
            journalName: showJournal ? journals[e.journalId]?.name : null,
          ),
    ];
  }

  /// Вклеивает записи запертых дневников в ленту тем же порядком, каким их
  /// отдаёт база: закреплённое сверху, дальше по дате.
  ///
  /// Двумя выборками, а не одной: остальные вкладки (карта, медиа, серия,
  /// виджет) живут на списке без запертых, и подмешивать их туда нельзя.
  static List<Entry> withLocked(List<Entry> open, List<Entry> locked) {
    if (locked.isEmpty) return open;
    return [...open, ...locked]..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        final byDate = b.entryDate.compareTo(a.entryDate);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });
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
