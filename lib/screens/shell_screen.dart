import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../theme/app_theme.dart';
import '../theme/feedback.dart';
import '../theme/wickly_design.dart';
import '../data/app_prefs.dart';
import '../data/entry_repository.dart';
import '../data/journal_lock.dart';
import '../data/journal_repository.dart';
import '../data/media_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../services/notifications_service.dart';
import '../services/prompts.dart';
import '../services/feed_service.dart';
import '../services/search_service.dart';
import '../services/stats_service.dart';
import '../services/update_service.dart';
import '../services/desk_service.dart';
import '../services/widget_service.dart';
import '../widgets/update_sheet.dart';
import '../utils/dates.dart';
import '../widgets/day_sheet.dart';
import '../widgets/desk_list.dart';
import '../widgets/desk_rail.dart';
import '../widgets/desk_today.dart';
import '../widgets/empty_state.dart';
import '../widgets/entry_card.dart';
import '../widgets/journal_gate.dart';
import '../widgets/panel_route.dart';
import 'calendar_screen.dart';
import 'desk_chronicle.dart';
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

  /// Замки дневников меняются мимо базы (пароль ввели — данные те же), поэтому
  /// на их тик выборки пересобираются вручную.
  StreamSubscription<void>? _lockChanges;

  /// Раскладка широкого окна: «Стол», «Разворот» или «Хроника».
  DeskLayout get _layout => DeskLayout.parse(AppPrefs.instance.desktopLayout);

  /// Дневники, теги, привычки и сегодняшний день для обвязки десктопа.
  DeskData _desk = DeskData.empty;
  String _deskSig = '';

  /// Открытая запись «Разворота» и выбранный день «Хроники».
  String? _selectedId;
  DateTime _selectedDay = DateTime.now();

  /// Дневник, выбранный в боковой панели: сужает ленту и список.
  DeskJournal? _journalFilter;

  @override
  void initState() {
    super.initState();
    _listenToWidget();
    _checkForUpdate();
    _lockChanges = JournalLock.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  /// Тихая проверка обновления при запуске: приложение раздаётся мимо магазина,
  /// поэтому о новой версии должно сообщать само. Молчит, если сети нет или
  /// версия последняя.
  ///
  /// Раз в сутки и не про ту версию, от которой уже отмахнулись. Замок запирает
  /// дневник при каждом уходе в фон, и оболочка после разблокировки собирается
  /// заново — без этих двух условий попап встречал бы человека на каждом входе.
  /// Ручная проверка в настройках выдержки не знает: там ответа ждут.
  Future<void> _checkForUpdate() async {
    final prefs = AppPrefs.instance;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - prefs.updateCheckedAt <
        const Duration(hours: 24).inMilliseconds) {
      return;
    }

    try {
      final current = (await PackageInfo.fromPlatform()).version;
      final info = await UpdateService.checkForUpdate(current);
      await prefs.setUpdateCheckedAt(now);
      if (!mounted || info == null) return;
      if (info.version == prefs.skippedUpdate) return;
      await UpdateSheet.show(context, info, current);
    } catch (_) {
      // Обновление — не то, ради чего стоит показывать ошибку на старте.
    }
  }

  @override
  void dispose() {
    _widgetTaps?.cancel();
    _lockChanges?.cancel();
    super.dispose();
  }

  /// Тап по виджету открывает редактор — сразу и с нужным настроением.
  Future<void> _listenToWidget() async {
    try {
      final launched = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (launched != null) _handleWidgetUri(launched);
      _widgetTaps = HomeWidget.widgetClicked.listen(_handleWidgetUri);
      _consumePendingWrite();
    } catch (_) {
      // Виджеты есть не на всякой платформе — это не повод падать.
    }
  }

  /// Открывает редактор, если сюда пришли по тапу на напоминание.
  void _consumePendingWrite() {
    if (!NotificationsService.pendingWrite) return;
    NotificationsService.pendingWrite = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _write(
          promptKey: Prompts.keyOfDay(
            AppPrefs.instance.promptPack,
            DateTime.now(),
          ),
        );
      }
    });
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

  Future<void> _write({String? promptKey, int? mood, DateTime? date}) async {
    final journalId = AppPrefs.instance.lastJournalId ?? 'default';
    await Navigator.of(context).push(
      pageOrPanel(
        context,
        (_) => EditorScreen(
          journalId: journalId,
          promptKey: promptKey,
          initialMood: mood,
          initialDate: date,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openEntry(Entry entry) async {
    // Запись запертого дневника лежит в ленте под блюром: сперва пароль, а за
    // ним сразу сама запись — ради неё на карточку и нажали. Проверка здесь, а
    // не в ленте, закрывает заодно лист дня и воспоминания: они открывают
    // записи этим же путём.
    if (JournalLock.isHidden(entry.journalId)) {
      final journal = await JournalRepository.instance.getById(entry.journalId);
      if (!mounted || journal == null) return;
      if (!await openJournalGate(context, journal)) return;
      if (!mounted) return;
    }

    await Navigator.of(context).push(
      pageOrPanel(
        context,
        (_) => ReaderScreen(
          entryId: entry.id,
          onEdit: (e) => Navigator.of(context).push(
            pageOrPanel(
              context,
              (_) => EditorScreen(entry: e, journalId: e.journalId),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  /// Поиск. [tag] уводит сразу в фильтр по тегу — так открываются теги из
  /// боковой панели и из самой записи.
  Future<void> _openSearch({String? query, String? tag}) async {
    final entries = await EntryRepository.instance.allEntries();
    final years = entries.map((e) => e.entryDate.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final tags = await DeskService.rankedTags();
    final picked = tag == null
        ? null
        : tags.where((t) => t.name == tag).firstOrNull;
    if (!mounted) return;
    await Navigator.of(context).push(
      pageOrPanel(
        context,
        (_) => SearchView(
          initialQuery: query,
          initialFilters:
              picked == null ? null : SearchFilters(tagId: picked.id),
          tags: tags,
          years: years.take(4).toList(),
          onSearch: (q, f) => SearchService.search(entries, q, filters: f),
          onOpen: _openEntry,
        ),
      ),
    );
  }

  Future<void> _openMemories() async {
    final now = DateTime.now();
    final memories = await EntryRepository.instance.onThisDay(now);
    final items = await FeedService.decorate(memories);
    if (!mounted) return;
    await Navigator.of(context).push(
      pageOrPanel(
        context,
        (_) => MemoriesView(day: now, memories: items, onOpen: _openEntry),
      ),
    );
  }

  Future<void> _openScreen(Widget screen) async {
    await Navigator.of(context).push(pageOrPanel(context, (_) => screen));
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
        RemindersScreen(onAnswer: (key) => _write(promptKey: key)),
      ),
    ),
    MoreItem(
      icon: Icons.search_rounded,
      title: tr('search'),
      subtitle: tr('search_start_sub'),
      onTap: _openSearch,
    ),
    MoreItem(
      icon: Icons.settings_rounded,
      title: tr('settings'),
      subtitle: tr('appearance_sub'),
      onTap: () => _openScreen(const SettingsScreen()),
    ),
  ];

  /// Пункты навигации — одни и те же для нижней панели телефона и бокового
  /// рельса десктопа.
  List<({IconData icon, IconData active, String label})> get _tabs => [
    (
      icon: Icons.view_agenda_outlined,
      active: Icons.view_agenda_rounded,
      label: tr('tab_feed'),
    ),
    (
      icon: Icons.calendar_month_outlined,
      active: Icons.calendar_month_rounded,
      label: tr('tab_calendar'),
    ),
    (icon: Icons.map_outlined, active: Icons.map_rounded, label: tr('tab_map')),
    (
      icon: Icons.grid_view_outlined,
      active: Icons.grid_view_rounded,
      label: tr('tab_media'),
    ),
    (
      icon: Icons.more_horiz_rounded,
      active: Icons.more_horiz_rounded,
      label: tr('tab_more'),
    ),
  ];

  void _selectTab(int i) {
    Haptics.tap();
    setState(() => _tab = ShellTab.values[i]);
  }

  /// Боковая панель широкого окна.
  Widget _rail(BuildContext context) => DeskRail(
        tabs: [
          for (final t in _tabs.take(4)) DeskTab(t.icon, t.active, t.label),
        ],
        // «Ещё» стоит внизу отдельно, поэтому на нём подсвечивать в списке
        // разделов нечего.
        selected: _tab == ShellTab.more ? -1 : _tab.index,
        onSelect: _selectTab,
        slim: !AppPrefs.instance.railExtended,
        onToggle: _toggleRail,
        onWrite: _write,
        onMore: () => _selectTab(ShellTab.more.index),
        onSettings: () => _openScreen(const SettingsScreen()),
        journals: _desk.journals,
        tags: _layout == DeskLayout.chronicle ? const [] : _desk.tags,
        habits: _layout == DeskLayout.chronicle ? _desk.habits : const [],
        syncLabel: _desk.syncLabel,
        onJournal: _pickJournal,
        onTag: (tag) => _openSearch(tag: tag),
      );

  /// Тап по дневнику в панели сужает ленту до него. Запертый сперва
  /// спрашивает пароль — панель показывает его замком, а не содержимым.
  Future<void> _pickJournal(DeskJournal picked) async {
    if (_journalFilter?.id == picked.id) {
      setState(() => _journalFilter = null);
      return;
    }
    if (picked.locked) {
      final journal = await JournalRepository.instance.getById(picked.id);
      if (!mounted || journal == null) return;
      if (!await openJournalGate(context, journal)) return;
      if (!mounted) return;
    }
    setState(() {
      _journalFilter = picked;
      _tab = ShellTab.feed;
      _selectedId = null;
    });
  }

  /// Подтягивает данные боковой панели, когда список записей изменился.
  void _syncDesk(List<Entry> entries) {
    final sig = '${entries.length}|${entries.isEmpty ? '' : entries.first.id}'
        '|${AppPrefs.instance.lastSyncAt?.millisecondsSinceEpoch ?? 0}'
        '|${_desk.journals.length}';
    if (sig == _deskSig) return;
    _deskSig = sig;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = await DeskService.load(entries);
      if (mounted) setState(() => _desk = data);
    });
  }

  Future<void> _toggleRail() async {
    Haptics.tap();
    await AppPrefs.instance.setRailExtended(!AppPrefs.instance.railExtended);
    if (mounted) setState(() {});
  }

  /// Сочетания клавиш. На десктопе без них приложение остаётся телефонным:
  /// за каждой мелочью тянешься мышью.
  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
        _write(),
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
        _openSearch(),
    const SingleActivator(LogicalKeyboardKey.keyB, control: true): () =>
        _toggleRail(),
    for (final (i, key) in const [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ].indexed)
      SingleActivator(key, control: true): () => _selectTab(i),
  };

  @override
  Widget build(BuildContext context) {
    final wide = WicklyDesign.isWide(context);

    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Focus(autofocus: true, child: _scaffold(context, wide)),
    );
  }

  /// Лента широкого окна в выбранной раскладке.
  Widget _deskFeed(List<Entry> entries) => switch (_layout) {
        DeskLayout.board => _boardLayout(entries),
        DeskLayout.spread => _spreadLayout(entries),
        DeskLayout.chronicle => _chronicleLayout(entries),
      };

  /// «Стол»: доска записей и сегодняшний день справа.
  Widget _boardLayout(List<Entry> entries) => Row(
        children: [
          Expanded(
            child: _FeedPane(
              entries: entries,
              onWrite: _write,
              onOpenEntry: _openEntry,
              onSearch: _openSearch,
              onMenu: () => _openScreen(const SettingsScreen()),
              onMemories: _openMemories,
              onStats: () => _openScreen(const MoodStatsContainer()),
              filterLabel: _journalFilter?.name,
              onClearFilter: () => setState(() => _journalFilter = null),
            ),
          ),
          DeskToday(
            data: _desk.today,
            onMood: _setTodayMood,
            onMarks: () => _write(),
            onStreak: () => _openScreen(const MoodStatsContainer()),
            onTracker: (_) => _openScreen(const TrackersContainer()),
            onMemory: _openMemories,
          ),
        ],
      );

  /// «Разворот»: список слева, открытая запись справа.
  Widget _spreadLayout(List<Entry> entries) {
    return FutureBuilder<List<EntryCardItem>>(
      future: FeedService.decorate(entries),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <EntryCardItem>[];
        final selected = items.any((i) => i.entry.id == _selectedId)
            ? _selectedId
            : items.firstOrNull?.entry.id;

        return Row(
          children: [
            DeskList(
              items: items,
              selectedId: selected,
              onOpen: (item) {
                if (item.locked) {
                  _openEntry(item.entry);
                  return;
                }
                setState(() => _selectedId = item.entry.id);
              },
              onSearch: _openSearch,
              journalFilter: _journalFilter?.name,
              onClearJournal: () => setState(() => _journalFilter = null),
            ),
            Expanded(
              child: selected == null
                  ? EmptyState(
                      icon: Icons.menu_book_rounded,
                      title: tr('feed_empty_title'),
                      subtitle: tr('feed_empty_sub'),
                    )
                  : ReaderScreen(
                      key: ValueKey(selected),
                      entryId: selected,
                      onTag: (tag) => _openSearch(tag: tag),
                      onEdit: (e) => Navigator.of(context).push(pageOrPanel(
                        context,
                        (_) => EditorScreen(entry: e, journalId: e.journalId),
                      )),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// «Хроника»: месяц цветом настроения и записи дня рядом.
  Widget _chronicleLayout(List<Entry> entries) {
    final now = DateTime.now();
    final ofMonth = entries
        .where((e) =>
            e.entryDate.year == _month.year && e.entryDate.month == _month.month)
        .toList();
    final monthEnd = DateTime(_month.year, _month.month + 1, 0);
    final to = monthEnd.isAfter(now) ? now : monthEnd;
    final ofDay =
        entries.where((e) => Dates.sameDay(e.entryDate, _selectedDay)).toList();

    return FutureBuilder<List<EntryCardItem>>(
      future: FeedService.decorate(ofDay),
      builder: (context, snapshot) => DeskChronicle(
        data: CalendarData(
          moodByDay: StatsService.moodByDay(entries),
          writtenDays: StatsService.writtenDays(entries),
          summary: StatsService.summary(
              entries, DateTime(_month.year, _month.month, 1), to),
          streak: StatsService.streak(entries, now: now),
          month: _month,
          now: now,
          entriesThisMonth: ofMonth.length,
          wordsThisMonth: ofMonth.fold<int>(0, (sum, e) => sum + e.wordCount),
          countByDay: DeskService.countByDay(entries),
        ),
        year: [
          for (final bar in DeskService.yearBars(entries, _month.year))
            YearBar(month: bar.month, count: bar.count, mood: bar.mood),
        ],
        selected: _selectedDay,
        onSelectDay: (day) => setState(() => _selectedDay = day),
        onChangeMonth: (m) => setState(() => _month = m),
        dayEntries: snapshot.data ?? const [],
        onOpenEntry: (item) => _openEntry(item.entry),
        onWriteOnDay: (day) => _write(date: day),
        onSearch: _openSearch,
        onMenu: () => _openScreen(const SettingsScreen()),
      ),
    );
  }

  /// Настроение дня прямо из колонки «Сегодня»: если запись сегодня уже есть —
  /// проставляем ей, иначе открываем редактор с этим настроением.
  Future<void> _setTodayMood(int mood) async {
    final today = await EntryRepository.instance.forDay(DateTime.now());
    if (today.isEmpty) {
      await _write(mood: mood);
      return;
    }
    await EntryRepository.instance.update(today.first.copyWith(mood: mood));
    _deskSig = '';
    if (mounted) setState(() {});
  }

  Widget _scaffold(BuildContext context, bool wide) {
    return Scaffold(
      body: StreamBuilder<List<Entry>>(
        stream: EntryRepository.instance.watchEntries(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Entry>[];
          // Виджет на домашнем экране живёт теми же данными, что и лента.
          if (snapshot.hasData) WidgetService.refresh(all);
          _syncDesk(all);
          // Дневник, выбранный в боковой панели, сужает все три раскладки.
          final entries = _journalFilter == null
              ? all
              : all.where((e) => e.journalId == _journalFilter!.id).toList();
          // Вкладка не «рождается», она сменяет предыдущую: проявление с
          // коротким подъёмом, без сдвига вбок — вкладки не соседние экраны,
          // а разные взгляды на одно и то же.
          final body = AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: AppTheme.emphasizedDecelerate,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.015),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _Body(
              key: ValueKey(_tab),
              tab: _tab,
              entries: entries,
              month: _month,
              moreItems: _moreItems,
              onChangeMonth: (m) => setState(() => _month = m),
              onWrite: _write,
              onWriteOn: (day) => _write(date: day),
              onOpenEntry: _openEntry,
              onSearch: _openSearch,
              onMemories: _openMemories,
              onStats: () => _openScreen(const MoodStatsContainer()),
              onSettings: () => _openScreen(const SettingsScreen()),
            ),
          );

          // Широкое окно: навигация уезжает вбок, а лента раскладывается так,
          // как выбрано в настройках.
          if (!wide) return body;
          return Row(
            children: [
              _rail(context),
              Expanded(
                child: _tab == ShellTab.feed ? _deskFeed(entries) : body,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab.index,
              onDestinationSelected: _selectTab,
              destinations: [
                for (final t in _tabs)
                  NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.active),
                    label: t.label,
                  ),
              ],
            ),
    );
  }
}

/// Вложения только видимых записей. Поток `watchAll` замок дневника не
/// фильтрует (media не знает про журналы), поэтому фото скрытых записей и
/// запертых дневников отсекаем здесь — по списку записей, который замок уже
/// отфильтровал.
List<Media> _visibleMedia(List<Media>? media, List<Entry> entries) {
  if (media == null || media.isEmpty) return const <Media>[];
  final visible = {for (final e in entries) e.id};
  return media.where((m) => visible.contains(m.entryId)).toList();
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

  /// Записать конкретным днём — из листа дня в календаре.
  final void Function(DateTime day) onWriteOn;
  final void Function(Entry) onOpenEntry;
  final VoidCallback onSearch;
  final VoidCallback onMemories;
  final VoidCallback onStats;
  final VoidCallback onSettings;

  const _Body({
    super.key,
    required this.tab,
    required this.entries,
    required this.month,
    required this.moreItems,
    required this.onChangeMonth,
    required this.onWrite,
    required this.onWriteOn,
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
        return _FeedPane(
          entries: entries,
          onWrite: onWrite,
          onOpenEntry: onOpenEntry,
          onSearch: onSearch,
          onMenu: onSettings,
          onMemories: onMemories,
          onStats: onStats,
        );

      case ShellTab.calendar:
        final ofMonth = entries
            .where(
              (e) =>
                  e.entryDate.year == month.year &&
                  e.entryDate.month == month.month,
            )
            .toList();
        // Охват считаем по прошедшим дням месяца: «17 из 31» в середине июля
        // выглядит как провал, хотя половина месяца ещё не наступила.
        final monthEnd = DateTime(month.year, month.month + 1, 0);
        final to = monthEnd.isAfter(now) ? now : monthEnd;
        return CalendarView(
          data: CalendarData(
            moodByDay: StatsService.moodByDay(entries),
            writtenDays: StatsService.writtenDays(entries),
            summary: StatsService.summary(
              entries,
              DateTime(month.year, month.month, 1),
              to,
            ),
            streak: StatsService.streak(entries, now: now),
            month: month,
            now: now,
            entriesThisMonth: ofMonth.length,
            wordsThisMonth: ofMonth.fold<int>(0, (sum, e) => sum + e.wordCount),
          ),
          onChangeMonth: onChangeMonth,
          onWrite: onWrite,
          // Раньше тап по дате открывал первую запись дня и молчал про
          // остальные, а с пустого дня нельзя было начать запись.
          onOpenDay: (day) async {
            final ofDay = entries
                .where(
                  (e) =>
                      e.entryDate.year == day.year &&
                      e.entryDate.month == day.month &&
                      e.entryDate.day == day.day,
                )
                .toList();
            final items = await FeedService.decorate(ofDay);
            if (!context.mounted) return;
            final picked = await showDaySheet(
              context,
              day: day,
              items: items,
              onWrite: () => onWriteOn(day),
            );
            if (picked != null) onOpenEntry(picked);
          },
        );

      case ShellTab.map:
        // Вложения тянем отдельным потоком — так же, как медиа-вкладка:
        // без них карточка места показывала градиент вместо снимка.
        return StreamBuilder<List<Media>>(
          stream: MediaRepository.instance.watchAll(),
          builder: (context, snapshot) => MapView(
            places: groupIntoPlaces(entries),
            // Только вложения видимых записей: поток media замок не фильтрует,
            // и без этого фото скрытой/запертой записи всплыло бы на карте.
            covers: coversByEntry(_visibleMedia(snapshot.data, entries)),
            onSearch: onSearch,
            onOpenPlace: (place) => onOpenEntry(place.latest),
          ),
        );

      case ShellTab.media:
        return StreamBuilder<List<Media>>(
          stream: MediaRepository.instance.watchAll(),
          builder: (context, snapshot) {
            // Замок не действует на поток media сам по себе: отсекаем
            // вложения скрытых записей и запертых дневников по видимым записям,
            // иначе галерея показывала бы их плитками в обход замка.
            final media = _visibleMedia(snapshot.data, entries);
            return MediaView(
              media: media,
              onSearch: onSearch,
              onOpen: (m) {
                final entry = entries
                    .where((e) => e.id == m.entryId)
                    .firstOrNull;
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


/// Лента как отдельная панель: её показывает и телефон, и «Стол» рядом с
/// колонкой «Сегодня».
///
/// Записи запертых дневников приходят отдельным потоком и живут только здесь —
/// под блюром и с замком. Серия, виджет, карта и медиа считаются по списку без
/// них.
class _FeedPane extends StatelessWidget {
  final List<Entry> entries;
  final VoidCallback onWrite;
  final void Function(Entry) onOpenEntry;
  final VoidCallback onSearch;
  final VoidCallback onMenu;
  final VoidCallback onMemories;
  final VoidCallback onStats;

  /// Имя дневника, которым сужена лента (выбран в боковой панели).
  final String? filterLabel;
  final VoidCallback? onClearFilter;

  const _FeedPane({
    required this.entries,
    required this.onWrite,
    required this.onOpenEntry,
    required this.onSearch,
    required this.onMenu,
    required this.onMemories,
    required this.onStats,
    this.filterLabel,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return StreamBuilder<List<Entry>>(
      stream: EntryRepository.instance.watchLockedEntries(),
      builder: (context, lockedSnapshot) {
        final feed = FeedService.withLocked(
          entries,
          lockedSnapshot.data ?? const [],
        );
        return FutureBuilder<List<EntryCardItem>>(
          future: FeedService.decorate(feed),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <EntryCardItem>[];
            final memories = items
                .where(
                  (i) =>
                      !i.locked &&
                      i.entry.entryDate.month == now.month &&
                      i.entry.entryDate.day == now.day &&
                      i.entry.entryDate.year != now.year,
                )
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
              onMenu: onMenu,
              onOpenMemories: onMemories,
              onOpenStreak: onStats,
              filterLabel: filterLabel,
              onClearFilter: onClearFilter,
            );
          },
        );
      },
    );
  }
}
