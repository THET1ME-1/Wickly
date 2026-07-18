import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../data/app_prefs.dart';
import '../data/entry_repository.dart';
import '../data/media_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../services/feed_service.dart';
import '../services/search_service.dart';
import '../services/stats_service.dart';
import '../services/widget_service.dart';
import '../utils/dates.dart';
import '../widgets/entry_card.dart';
import 'calendar_screen.dart';
import 'catalog_manager_screen.dart';
import 'editor_screen.dart';
import 'feed_screen.dart';
import 'journals_container.dart';
import 'map_screen.dart';
import 'media_screen.dart';
import 'memories_screen.dart';
import 'mood_stats_container.dart';
import 'more_screen.dart';
import 'reader_screen.dart';
import 'reminders_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'trackers_container.dart';

/// Вкладки нижней навигации.
enum ShellTab { feed, calendar, map, media, more }

/// Каркас приложения: четыре взгляда на одни и те же записи плюс «Ещё».
///
/// Лента, календарь, карта и медиа — это один дневник в четырёх проекциях,
/// поэтому они живут вкладками, а не отдельными экранами: переключение не
/// теряет контекст.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  late ShellTab _tab = _startTab;

  /// Показываемый месяц календаря.
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  StreamSubscription<Uri?>? _widgetTaps;

  @override
  void initState() {
    super.initState();
    _listenToWidget();
  }

  @override
  void dispose() {
    _widgetTaps?.cancel();
    super.dispose();
  }

  /// Тап по виджету открывает редактор — сразу и с нужным настроением.
  Future<void> _listenToWidget() async {
    try {
      final launched = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launched != null) _handleWidgetUri(launched);
      _widgetTaps = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    } catch (_) {
      // Виджеты есть не на всякой платформе — это не повод падать.
    }
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || uri.host != 'write') return;
    final mood = int.tryParse(uri.queryParameters['mood'] ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) => _write(mood: mood));
  }

  static ShellTab get _startTab {
    final name = AppPrefs.instance.startScreen;
    return ShellTab.values.firstWhere(
      (t) => t.name == name,
      orElse: () => ShellTab.feed,
    );
  }

  // ----------------------------- Переходы -----------------------------

  Future<void> _write({String? promptKey, int? mood}) async {
    final journalId = AppPrefs.instance.lastJournalId ?? 'default';
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EditorScreen(
        journalId: journalId,
        promptKey: promptKey,
        initialMood: mood,
      ),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _openEntry(Entry entry) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(
        entryId: entry.id,
        onEdit: (e) => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EditorScreen(entry: e, journalId: e.journalId),
        )),
      ),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _openSearch() async {
    final entries = await EntryRepository.instance.allEntries();
    final years = entries.map((e) => e.entryDate.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchView(
        years: years.take(4).toList(),
        onSearch: (q, f) => SearchService.search(entries, q, filters: f),
        onOpen: _openEntry,
      ),
    ));
  }

  Future<void> _openMemories() async {
    final now = DateTime.now();
    final memories = await EntryRepository.instance.onThisDay(now);
    final items = await FeedService.decorate(memories);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MemoriesView(
        day: now,
        memories: items,
        onOpen: _openEntry,
      ),
    ));
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  /// Пункты вкладки «Ещё».
  List<MoreItem> get _moreItems => [
        MoreItem(
          icon: Icons.menu_book_rounded,
          title: tr('journals'),
          subtitle: tr('journals_and_covers'),
          onTap: () => _openScreen(const JournalsContainer()),
        ),
        MoreItem(
          icon: Icons.insights_rounded,
          title: tr('set_mood'),
          subtitle: tr('mood_x_weather'),
          onTap: () => _openScreen(const MoodStatsContainer()),
        ),
        MoreItem(
          icon: Icons.water_drop_rounded,
          title: tr('trackers'),
          subtitle: tr('habits'),
          onTap: () => _openScreen(const TrackersContainer()),
        ),
        MoreItem(
          icon: Icons.history_rounded,
          title: tr('on_this_day'),
          subtitle: tr('memories_morning'),
          onTap: _openMemories,
        ),
        MoreItem(
          icon: Icons.mood_rounded,
          title: tr('emotions_and_activities'),
          subtitle: tr('mood_behind'),
          onTap: () => _openScreen(const CatalogManagerScreen()),
        ),
        MoreItem(
          icon: Icons.notifications_rounded,
          title: tr('reminders'),
          subtitle: tr('prompt_of_day'),
          onTap: () => _openScreen(
              RemindersScreen(onAnswer: (key) => _write(promptKey: key))),
        ),
        MoreItem(
          icon: Icons.search_rounded,
          title: tr('search'),
          subtitle: tr('search_section_photos'),
          onTap: _openSearch,
        ),
        MoreItem(
          icon: Icons.settings_rounded,
          title: tr('settings'),
          subtitle: tr('appearance_sub'),
          onTap: () => _openScreen(const SettingsScreen()),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Entry>>(
        stream: EntryRepository.instance.watchEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <Entry>[];
          // Виджет на домашнем экране живёт теми же данными, что и лента.
          if (snapshot.hasData) WidgetService.refresh(entries);
          return _Body(
            tab: _tab,
            entries: entries,
            month: _month,
            moreItems: _moreItems,
            onChangeMonth: (m) => setState(() => _month = m),
            onWrite: _write,
            onOpenEntry: _openEntry,
            onSearch: _openSearch,
            onMemories: _openMemories,
            onStats: () => _openScreen(const MoodStatsContainer()),
            onSettings: () => _openScreen(const SettingsScreen()),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (i) =>
            setState(() => _tab = ShellTab.values[i]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.view_agenda_outlined),
            selectedIcon: const Icon(Icons.view_agenda_rounded),
            label: tr('tab_feed'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: tr('tab_calendar'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded),
            label: tr('tab_map'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: tr('tab_media'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_rounded),
            label: tr('tab_more'),
          ),
        ],
      ),
    );
  }
}

/// Тело вкладки. Вынесено отдельно, чтобы каждая вкладка сама достраивала свои
/// данные и лента не пересчитывала карту.
class _Body extends StatelessWidget {
  final ShellTab tab;
  final List<Entry> entries;
  final DateTime month;
  final List<MoreItem> moreItems;
  final ValueChanged<DateTime> onChangeMonth;
  final VoidCallback onWrite;
  final void Function(Entry) onOpenEntry;
  final VoidCallback onSearch;
  final VoidCallback onMemories;
  final VoidCallback onStats;
  final VoidCallback onSettings;

  const _Body({
    required this.tab,
    required this.entries,
    required this.month,
    required this.moreItems,
    required this.onChangeMonth,
    required this.onWrite,
    required this.onOpenEntry,
    required this.onSearch,
    required this.onMemories,
    required this.onStats,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    switch (tab) {
      case ShellTab.feed:
        return FutureBuilder<List<EntryCardItem>>(
          future: FeedService.decorate(entries),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <EntryCardItem>[];
            final memories = items
                .where((i) =>
                    i.entry.entryDate.month == now.month &&
                    i.entry.entryDate.day == now.day &&
                    i.entry.entryDate.year != now.year)
                .toList();
            return FeedView(
              data: FeedData(
                items: items,
                streak: StatsService.streak(entries, now: now),
                memories: memories,
                period: Dates.monthYear(now),
                lastWeek: FeedService.lastWeek(entries, now),
                now: now,
              ),
              onWrite: onWrite,
              onOpenEntry: onOpenEntry,
              onSearch: onSearch,
              onMenu: onSettings,
              onOpenMemories: onMemories,
              onOpenStreak: onStats,
            );
          },
        );

      case ShellTab.calendar:
        // Охват считаем по прошедшим дням месяца: «17 из 31» в середине июля
        // выглядит как провал, хотя половина месяца ещё не наступила.
        final monthEnd = DateTime(month.year, month.month + 1, 0);
        final to = monthEnd.isAfter(now) ? now : monthEnd;
        return CalendarView(
          data: CalendarData(
            moodByDay: StatsService.moodByDay(entries),
            writtenDays: StatsService.writtenDays(entries),
            summary: StatsService.summary(
                entries, DateTime(month.year, month.month, 1), to),
            streak: StatsService.streak(entries, now: now),
            month: month,
            now: now,
          ),
          onChangeMonth: onChangeMonth,
          onWrite: onWrite,
          onOpenDay: (day) {
            final ofDay = entries
                .where((e) =>
                    e.entryDate.year == day.year &&
                    e.entryDate.month == day.month &&
                    e.entryDate.day == day.day)
                .toList();
            if (ofDay.isNotEmpty) onOpenEntry(ofDay.first);
          },
        );

      case ShellTab.map:
        return MapView(
          places: groupIntoPlaces(entries),
          onSearch: onSearch,
          onOpenPlace: (place) => onOpenEntry(place.latest),
        );

      case ShellTab.media:
        return StreamBuilder<List<Media>>(
          stream: MediaRepository.instance.watchAll(),
          builder: (context, snapshot) {
            final media = snapshot.data ?? const <Media>[];
            return MediaView(
              media: media,
              onSearch: onSearch,
              onOpen: (m) {
                final entry =
                    entries.where((e) => e.id == m.entryId).firstOrNull;
                if (entry != null) onOpenEntry(entry);
              },
            );
          },
        );

      case ShellTab.more:
        return MoreScreen(items: moreItems);
    }
  }
}
