import 'package:flutter/material.dart';

import '../data/app_prefs.dart';
import '../data/entry_repository.dart';
import '../data/media_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../services/feed_service.dart';
import '../services/stats_service.dart';
import '../utils/dates.dart';
import '../widgets/entry_card.dart';
import 'calendar_screen.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'media_screen.dart';
import 'more_screen.dart';

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

  static ShellTab get _startTab {
    final name = AppPrefs.instance.startScreen;
    return ShellTab.values.firstWhere(
      (t) => t.name == name,
      orElse: () => ShellTab.feed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Entry>>(
        stream: EntryRepository.instance.watchEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const <Entry>[];
          return _Body(
            tab: _tab,
            entries: entries,
            month: _month,
            onChangeMonth: (m) => setState(() => _month = m),
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
  final ValueChanged<DateTime> onChangeMonth;

  const _Body({
    required this.tab,
    required this.entries,
    required this.month,
    required this.onChangeMonth,
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
        );

      case ShellTab.map:
        return MapView(places: groupIntoPlaces(entries));

      case ShellTab.media:
        return StreamBuilder<List<Media>>(
          stream: MediaRepository.instance.watchAll(),
          builder: (context, snapshot) =>
              MediaView(media: snapshot.data ?? const <Media>[]),
        );

      case ShellTab.more:
        return const MoreScreen();
    }
  }
}
