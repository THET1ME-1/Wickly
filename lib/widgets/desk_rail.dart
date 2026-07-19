import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import 'brand_mark.dart';

/// Дневник в боковой панели.
class DeskJournal {
  final String id;
  final String name;
  final String? cover;
  final int count;
  final bool locked;

  const DeskJournal({
    required this.id,
    required this.name,
    this.cover,
    this.count = 0,
    this.locked = false,
  });
}

/// Привычка в боковой панели: имя и длина серии.
class DeskHabit {
  final String id;
  final String name;
  final int days;

  const DeskHabit({required this.id, required this.name, this.days = 0});
}

/// Раздел навигации.
class DeskTab {
  final IconData icon;
  final IconData active;
  final String label;

  const DeskTab(this.icon, this.active, this.label);
}

/// Боковая панель широкого окна.
///
/// Не «нижняя панель, повёрнутая вбок»: кроме разделов здесь живут дневники со
/// счётчиками и теги — то, ради чего на телефоне приходится уходить на другие
/// экраны. Сворачивается до одних значков ([slim]).
class DeskRail extends StatelessWidget {
  final List<DeskTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  final bool slim;
  final VoidCallback? onToggle;
  final VoidCallback? onWrite;
  final VoidCallback? onSettings;
  final VoidCallback? onMore;

  final List<DeskJournal> journals;
  final List<String> tags;
  final List<DeskHabit> habits;
  final void Function(DeskJournal journal)? onJournal;
  final void Function(String tag)? onTag;

  /// Строка о синхронизации внизу («Синхронизировано · 12 минут назад»).
  final String? syncLabel;

  const DeskRail({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    this.slim = false,
    this.onToggle,
    this.onWrite,
    this.onSettings,
    this.onMore,
    this.journals = const [],
    this.tags = const [],
    this.habits = const [],
    this.onJournal,
    this.onTag,
    this.syncLabel,
  });

  static const double wideWidth = 246;
  static const double slimWidth = 76;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: slim ? slimWidth : wideWidth,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            slim ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _brand(context),
          _writeButton(context),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: slim ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  _NavItem(
                    tab: tabs[i],
                    on: i == selected,
                    slim: slim,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ),
          if (!slim)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (journals.isNotEmpty) ...[
                      _Label(tr('journals')),
                      for (final j in journals)
                        _JournalRow(journal: j, onTap: () => onJournal?.call(j)),
                    ],
                    if (habits.isNotEmpty) ...[
                      _Label(tr('habits')),
                      for (final h in habits) _HabitRow(habit: h),
                    ],
                    if (tags.isNotEmpty) ...[
                      _Label(tr('tags')),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final t in tags)
                              _TagChip(tag: t, onTap: () => onTag?.call(t)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          _foot(context, scheme),
        ],
      ),
    );
  }

  Widget _brand(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (slim) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 2),
        child: BrandMark(size: 28),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
      child: Row(
        children: [
          const BrandMark(size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Wickly',
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_open_rounded, size: 20),
            tooltip: tr('rail_collapse'),
            onPressed: onToggle,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _writeButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(slim ? 0 : 12, 16, slim ? 0 : 12, 18),
      child: slim
          ? Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onWrite,
                    child: Icon(Icons.edit_rounded,
                        color: scheme.onPrimary, size: 22),
                  ),
                ),
              ),
            )
          : SizedBox(
              height: 46,
              child: Material(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(23),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onWrite,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, size: 18, color: scheme.onPrimary),
                      const SizedBox(width: 9),
                      Text(
                        tr('write'),
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _foot(BuildContext context, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment:
            slim ? CrossAxisAlignment.center : CrossAxisAlignment.stretch,
        children: [
          if (!slim && syncLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: MoodPalette.color(context, 5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      syncLabel!,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        color: scheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: slim ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NavItem(
                  tab: DeskTab(Icons.more_horiz_rounded,
                      Icons.more_horiz_rounded, tr('tab_more')),
                  on: false,
                  slim: slim,
                  onTap: onMore,
                ),
                _NavItem(
                  tab: DeskTab(Icons.settings_rounded, Icons.settings_rounded,
                      tr('settings')),
                  on: false,
                  slim: slim,
                  onTap: onSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DeskTab tab;
  final bool on;
  final bool slim;
  final VoidCallback? onTap;

  const _NavItem({
    required this.tab,
    required this.on,
    required this.slim,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = on ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;

    final body = Material(
      color: on ? scheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: slim
              ? Icon(on ? tab.active : tab.icon, size: 22, color: fg)
              : Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(on ? tab.active : tab.icon, size: 20, color: fg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tab.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: slim ? 12 : 4, vertical: 1),
      child: slim ? Tooltip(message: tab.label, child: body) : body,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.1,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
}

class _JournalRow extends StatelessWidget {
  final DeskJournal journal;
  final VoidCallback? onTap;

  const _JournalRow({required this.journal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: CoverPalette.gradient(journal.cover),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    journal.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (journal.locked)
                  Icon(Icons.lock_rounded, size: 13, color: scheme.outline)
                else
                  Text(
                    '${journal.count}',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 11.5,
                      color: scheme.outline,
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

class _HabitRow extends StatelessWidget {
  final DeskHabit habit;
  const _HabitRow({required this.habit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            trf('days_short', {'n': '${habit.days}'}),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 11.5,
              color: scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onTap;

  const _TagChip({required this.tag, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            '#$tag',
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
