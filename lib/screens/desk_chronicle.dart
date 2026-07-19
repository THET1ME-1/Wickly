import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/entry_card.dart';
import 'calendar_screen.dart';

/// Месяц года в верхней полосе: сколько написано и каким он был.
class YearBar {
  final int month;
  final int count;
  final double? mood;

  const YearBar({required this.month, this.count = 0, this.mood});
}

/// «Хроника» — календарь во весь экран с записями выбранного дня рядом.
///
/// Лента отвечает на вопрос «что я писал», хроника — «как я жил»: месяц
/// раскрашен настроением, год виден полосой, а день не прячется в шторку снизу,
/// а раскрывается колонкой справа.
class DeskChronicle extends StatelessWidget {
  final CalendarData data;
  final List<YearBar> year;

  final DateTime selected;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<DateTime> onChangeMonth;

  final List<EntryCardItem> dayEntries;
  final void Function(EntryCardItem item)? onOpenEntry;
  final ValueChanged<DateTime>? onWriteOnDay;

  final VoidCallback? onSearch;
  final VoidCallback? onMenu;

  const DeskChronicle({
    super.key,
    required this.data,
    required this.selected,
    required this.onSelectDay,
    required this.onChangeMonth,
    this.year = const [],
    this.dayEntries = const [],
    this.onOpenEntry,
    this.onWriteOnDay,
    this.onSearch,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _toolbar(context),
              Expanded(
                child: Padding(
            padding: const EdgeInsets.fromLTRB(
                WicklyDesign.deskPad, 16, WicklyDesign.deskPad, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context),
                const SizedBox(height: 16),
                _weekdays(context),
                const SizedBox(height: 8),
                Expanded(child: _month(context)),
                const SizedBox(height: 16),
                _stats(context),
              ],
            ),
          ),
              ),
            ],
          ),
        ),
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border(left: BorderSide(color: scheme.outlineVariant)),
          ),
          child: _day(context),
        ),
      ],
    );
  }

  /// Панель инструментов: месяц с итогом строкой и поиск — та же, что у ленты,
  /// чтобы хроника не выглядела другим приложением.
  Widget _toolbar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = DateTime(data.month.year, data.month.month + 1, 0).day;
    final written = data.writtenDays
        .where((k) => k ~/ 100 == data.month.year * 100 + data.month.month)
        .length;
    final avg = data.summary.daysWithMood == 0 ? null : data.summary.average;

    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: WicklyDesign.deskPad),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Dates.monthYear(data.month),
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    trf('month_written',
                        {'a': '$written', 'b': Dates.daysOf(days)}),
                    if (avg != null)
                      '${tr('mood_average')} — '
                          '${tr(MoodPalette.labelKey(avg.round())).toLowerCase()}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (onSearch != null)
            _SearchBox(onTap: onSearch!),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: tr('settings'),
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }

  // ----------------------------- Шапка -----------------------------

  Widget _header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: tr('prev_month'),
          onPressed: () =>
              onChangeMonth(DateTime(data.month.year, data.month.month - 1)),
        ),
        Text(
          Dates.monthOnly(data.month),
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontWeight: FontWeight.w800,
            fontSize: 21,
            letterSpacing: -0.4,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${data.month.year}',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 12,
            color: scheme.outline,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: tr('next_month'),
          onPressed: () =>
              onChangeMonth(DateTime(data.month.year, data.month.month + 1)),
        ),
        const Spacer(),
        // Полоса года: высота столбика — сколько написано, цвет — каким был
        // месяц. Отсюда виден год целиком, без листания.
        for (final bar in year) ...[
          _YearBarView(
            bar: bar,
            on: bar.month == data.month.month,
            onTap: () => onChangeMonth(DateTime(data.month.year, bar.month)),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }

  Widget _weekdays(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (final h in Dates.weekdayHeaders())
          Expanded(
            child: Text(
              h.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.7,
                color: scheme.outline,
              ),
            ),
          ),
      ],
    );
  }

  // ----------------------------- Месяц -----------------------------

  Widget _month(BuildContext context) {
    final first = DateTime(data.month.year, data.month.month, 1);
    final lead = (first.weekday + 6) % 7;
    final days = DateTime(data.month.year, data.month.month + 1, 0).day;
    final cells = ((lead + days) / 7).ceil() * 7;

    // Клетки растягиваются на всю отведённую высоту: месяц должен заполнять
    // экран, а не висеть таблицей в верхней трети.
    return LayoutBuilder(builder: (context, box) {
      final rows = cells ~/ 7;
      final cellW = (box.maxWidth - 8 * 6) / 7;
      final cellH = (box.maxHeight - 8 * (rows - 1)) / rows;
      return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: cellH <= 0 ? 1 : cellW / cellH,
      ),
      itemCount: cells,
      itemBuilder: (context, i) {
        final dayNum = i - lead + 1;
        final inMonth = dayNum >= 1 && dayNum <= days;
        final date = DateTime(data.month.year, data.month.month, dayNum);
        final key = date.year * 10000 + date.month * 100 + date.day;
        return _DayCell(
          date: date,
          inMonth: inMonth,
          mood: inMonth ? data.moodByDay[key] : null,
          written: inMonth && data.writtenDays.contains(key),
          count: inMonth ? (data.countByDay[key] ?? 0) : 0,
          selected: inMonth && Dates.sameDay(date, selected),
          today: inMonth && Dates.sameDay(date, data.now),
          onTap: inMonth ? () => onSelectDay(date) : null,
        );
      },
      );
    });
  }

  Widget _stats(BuildContext context) {
    final days = DateTime(data.month.year, data.month.month + 1, 0).day;
    final written = data.writtenDays
        .where((k) => k ~/ 100 == data.month.year * 100 + data.month.month)
        .length;
    final avg = data.summary.daysWithMood == 0 ? null : data.summary.average;

    return Row(
      children: [
        _stat(context, '$written', tr('days_written')),
        const SizedBox(width: 10),
        _stat(context, '${data.streak.current}', tr('days_in_row')),
        const SizedBox(width: 10),
        _stat(context, Dates.grouped(data.wordsThisMonth), tr('month_words')),
        const SizedBox(width: 10),
        _stat(
          context,
          avg == null ? '—' : avg.toStringAsFixed(1).replaceAll('.', ','),
          tr('mood_average'),
          hint: '$days',
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label,
      {String? hint}) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 11.5,
                color: scheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------- День -----------------------------

  Widget _day(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            Dates.dayWithWeekday(selected).toUpperCase(),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.1,
              color: scheme.outline,
            ),
          ),
        ),
        for (final item in dayEntries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EntryCard(
              item: item,
              onTap: () => onOpenEntry?.call(item),
            ),
          ),
        Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onWriteOnDay?.call(selected),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.add_rounded,
                        size: 20, color: scheme.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('write_on_day'),
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('write_on_day_sub'),
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _YearBarView extends StatelessWidget {
  final YearBar bar;
  final bool on;
  final VoidCallback onTap;

  const _YearBarView({required this.bar, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final height = bar.count == 0
        ? 14.0
        : (14 + (bar.count.clamp(0, 30) / 30) * 20).toDouble();

    return Tooltip(
      message: Dates.monthOnly(DateTime(2026, bar.month)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          width: 9,
          height: 36,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 9,
              height: on ? 36 : height,
              decoration: BoxDecoration(
                color: bar.mood == null
                    ? scheme.surfaceContainerHighest
                    : MoodPalette.color(context, bar.mood!.round()),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Клетка месяца: число, полоса настроения снизу и счётчик записей.
class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool inMonth;
  final double? mood;
  final bool written;
  final int count;
  final bool selected;
  final bool today;
  final VoidCallback? onTap;

  const _DayCell({
    required this.date,
    required this.inMonth,
    required this.written,
    required this.count,
    required this.selected,
    required this.today,
    this.mood,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: inMonth ? 1 : 0.32,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(color: scheme.primary, width: 2)
                  : today
                      ? Border.all(color: scheme.outlineVariant)
                      : null,
            ),
            child: Stack(
              children: [
                // Полоса настроения по низу клетки: цвет дня виден с другого
                // конца комнаты, число записей — вблизи.
                if (mood != null || written)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.34,
                        widthFactor: 1,
                        child: ColoredBox(
                          color: mood == null
                              ? scheme.surfaceContainerHighest
                              : MoodPalette.color(context, mood!.round()),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 8, 9, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      if (count > 0)
                        Text(
                          '$count',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 10.5,
                            color: mood == null
                                ? scheme.outline
                                : MoodPalette.on(context, mood!.round()),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


/// Строка поиска в шапке хроники — форма та же, что в ленте.
class _SearchBox extends StatefulWidget {
  final VoidCallback onTap;
  const _SearchBox({required this.onTap});

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 300,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hover
                ? scheme.surfaceContainerHighest
                : scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hover ? scheme.outline : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr('search_hint'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'Ctrl F',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
