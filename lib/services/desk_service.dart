import '../data/app_prefs.dart';
import '../data/catalog_repository.dart';
import '../data/entry_repository.dart';
import '../data/journal_lock.dart';
import '../data/journal_repository.dart';
import '../data/tracker_repository.dart';
import '../l10n/strings.dart';
import '../models/catalog.dart';
import '../models/entry.dart';
import '../utils/catalog_names.dart';
import '../utils/dates.dart';
import '../widgets/desk_list.dart';
import '../widgets/desk_rail.dart';
import '../widgets/desk_today.dart';
import 'feed_service.dart';
import 'habit_stats.dart';
import 'stats_service.dart';

/// Всё, чем живёт обвязка широкого окна: боковая панель и колонка «Сегодня».
class DeskData {
  final List<DeskJournal> journals;
  final List<String> tags;
  final List<DeskHabit> habits;
  final TodayData today;
  final String? syncLabel;

  const DeskData({
    this.journals = const [],
    this.tags = const [],
    this.habits = const [],
    this.today = const TodayData(),
    this.syncLabel,
  });

  static const empty = DeskData();
}

/// Собирает данные для десктопной обвязки.
///
/// Одним заходом на весь экран: дневники, теги, привычки, сегодняшний день и
/// воспоминание нужны сразу и вместе, а по отдельности каждый тянул бы свой
/// круг запросов на каждый тик ленты.
class DeskService {
  const DeskService._();

  /// Сколько тегов помещается в боковой панели, чтобы она не превратилась в
  /// облако тегов.
  static const _tagLimit = 8;

  /// Теги дневника, самые ходовые впереди. Ими живут и боковая панель, и
  /// фильтры поиска на телефоне.
  static Future<List<Tag>> rankedTags({int limit = 12}) async {
    final tags = await CatalogRepository.instance.tags();
    final links =
        await CatalogRepository.instance.allLinks('entry_tags', 'tag_id');
    final usage = <String, int>{};
    for (final ids in links.values) {
      for (final id in ids) {
        usage[id] = (usage[id] ?? 0) + 1;
      }
    }
    final ranked = [...tags]
      ..sort((a, b) => (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0));
    return [
      for (final t in ranked.take(limit))
        if ((usage[t.id] ?? 0) > 0) t,
    ];
  }

  static Future<DeskData> load(List<Entry> entries, {DateTime? now}) async {
    final today = now ?? DateTime.now();

    final journals = await JournalRepository.instance.all();
    final counts = await JournalRepository.instance.counts();
    final trackers = await TrackerRepository.instance.trackers();
    final values = await TrackerRepository.instance.valuesForDay(today);
    // Теги в панели — самые ходовые: редкий тег там только занимает строку.
    final ranked = await rankedTags(limit: _tagLimit);

    return DeskData(
      journals: [
        for (final j in journals)
          DeskJournal(
            id: j.id,
            name: j.name,
            cover: j.cover,
            count: counts[j.id] ?? 0,
            locked: JournalLock.isHidden(j.id),
          ),
      ],
      tags: [for (final t in ranked) t.name],
      habits: await _habits(trackers, today),
      today: await _today(entries, trackers, values, today),
      syncLabel: _syncLabel(),
    );
  }

  static Future<List<DeskHabit>> _habits(
    List<Tracker> trackers,
    DateTime now,
  ) async {
    final habits = trackers.where((t) => t.kind == TrackerKind.habit).toList();
    final out = <DeskHabit>[];
    for (final h in habits.take(4)) {
      final byDay = await TrackerRepository.instance.range(
        h.id,
        now.subtract(const Duration(days: 120)),
        now,
      );
      final stats = HabitMath.of(byDay, now: now);
      out.add(DeskHabit(
        id: h.id,
        name: CatalogNames.of(h),
        days: stats.streak,
      ));
    }
    return out;
  }

  static Future<TodayData> _today(
    List<Entry> entries,
    List<Tracker> trackers,
    Map<String, double> values,
    DateTime now,
  ) async {
    final ofToday =
        entries.where((e) => Dates.sameDay(e.entryDate, now)).toList();

    // Отметки дня: эмоции и действия всех сегодняшних записей одним списком.
    final marks = <String>[];
    if (ofToday.isNotEmpty) {
      final emotions = {
        for (final e in await CatalogRepository.instance.emotions()) e.id: e,
      };
      final activities = {
        for (final a in await CatalogRepository.instance.activities()) a.id: a,
      };
      final emoLinks = await CatalogRepository.instance
          .allLinks('entry_emotions', 'emotion_id');
      final actLinks = await CatalogRepository.instance
          .allLinks('entry_activities', 'activity_id');
      for (final e in ofToday) {
        for (final id in emoLinks[e.id] ?? const <String>[]) {
          final item = emotions[id];
          if (item != null) marks.add(CatalogNames.of(item));
        }
        for (final id in actLinks[e.id] ?? const <String>[]) {
          final item = activities[id];
          if (item != null) marks.add(CatalogNames.of(item));
        }
      }
    }

    final memories = await EntryRepository.instance.onThisDay(now);
    final decorated =
        memories.isEmpty ? const [] : await FeedService.decorate([memories.first]);

    return TodayData(
      streak: StatsService.streak(entries, now: now),
      lastWeek: FeedService.lastWeek(entries, now),
      mood: ofToday.map((e) => e.mood).whereType<int>().firstOrNull,
      marks: marks.toSet().toList(),
      trackers: [
        for (final t in trackers.take(4))
          TodayTracker(
            id: t.id,
            name: CatalogNames.of(t),
            value: values[t.id] ?? 0,
            goal: t.goal ?? 1,
            habit: t.kind == TrackerKind.habit,
            unit: t.unit == null
                ? null
                : (hasTr(t.unit!) ? tr(t.unit!) : t.unit),
          ),
      ],
      memory: decorated.isEmpty ? null : decorated.first,
      memoryYears: memories.isEmpty
          ? 0
          : now.year - memories.first.entryDate.year,
    );
  }

  static String? _syncLabel() {
    final at = AppPrefs.instance.lastSyncAt;
    if (at == null) return tr('sync_never');
    return '${tr('synced')} · ${Dates.relativeDay(at).toLowerCase()}';
  }

  /// Полоса года для хроники: сколько записей в месяце и каким он был.
  static List<({int month, int count, double? mood})> yearBars(
    List<Entry> entries,
    int year,
  ) {
    final counts = List<int>.filled(13, 0);
    final moodSum = List<double>.filled(13, 0);
    final moodCount = List<int>.filled(13, 0);
    for (final e in entries) {
      if (e.entryDate.year != year) continue;
      counts[e.entryDate.month]++;
      if (e.mood != null) {
        moodSum[e.entryDate.month] += e.mood!;
        moodCount[e.entryDate.month]++;
      }
    }
    return [
      for (var m = 1; m <= 12; m++)
        (
          month: m,
          count: counts[m],
          mood: moodCount[m] == 0 ? null : moodSum[m] / moodCount[m],
        ),
    ];
  }

  /// Записей в каждом дне — число в клетке месяца.
  static Map<int, int> countByDay(List<Entry> entries) {
    final out = <int, int>{};
    for (final e in entries) {
      final d = e.entryDate;
      final key = d.year * 10000 + d.month * 100 + d.day;
      out[key] = (out[key] ?? 0) + 1;
    }
    return out;
  }
}

/// Раскладка широкого окна, выбранная в настройках.
enum DeskLayout {
  board,
  spread,
  chronicle;

  static DeskLayout parse(String? raw) => DeskLayout.values.firstWhere(
        (l) => l.name == raw,
        orElse: () => DeskLayout.board,
      );

  String get title => switch (this) {
        DeskLayout.board => tr('layout_board'),
        DeskLayout.spread => tr('layout_spread'),
        DeskLayout.chronicle => tr('layout_chronicle'),
      };

  String get subtitle => switch (this) {
        DeskLayout.board => tr('layout_board_sub'),
        DeskLayout.spread => tr('layout_spread_sub'),
        DeskLayout.chronicle => tr('layout_chronicle_sub'),
      };
}

/// Фильтр списка «Разворота» — вынесен сюда, чтобы экран не тянул виджеты.
typedef DeskListFilter = DeskFilter;
