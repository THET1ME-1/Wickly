import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/entry.dart';
import '../services/search_service.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../widgets/reveal.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/media_thumb.dart';
import '../widgets/pressable.dart';

/// Поиск по дневнику.
///
/// Один запрос ищет и в тексте, и в метаданных, и в надписях на фотографиях —
/// поэтому находки на фото вынесены отдельной секцией: это другой способ
/// вспомнить, и мешать его с текстом нельзя.
class SearchView extends StatefulWidget {
  final Future<SearchResult> Function(String query, SearchFilters filters)
      onSearch;
  final void Function(Entry entry)? onOpen;

  /// Годы, за которые есть записи — из них строится фильтр.
  final List<int> years;

  const SearchView({
    super.key,
    required this.onSearch,
    this.onOpen,
    this.years = const [],
  });

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();

  /// Что уже показывали — чтобы каскад не перезапускался при прокрутке.
  final Set<Object> _shown = <Object>{};
  SearchFilters _filters = const SearchFilters();
  SearchResult _result = const SearchResult();
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final result = await widget.onSearch(_controller.text, _filters);
    if (!mounted) return;
    setState(() {
      _result = result;
      _searched = _controller.text.trim().isNotEmpty || !_filters.isEmpty;
    });
  }

  void _setFilters(SearchFilters f) {
    setState(() => _filters = f);
    _run();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 8,
                  WicklyDesign.sidePad(context, column: WicklyDesign.listWidth), 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: tr('search_hint'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 13),
                        suffixIcon: _controller.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  _run();
                                },
                              ),
                      ),
                      onChanged: (_) {
                        setState(() {});
                        _run();
                      },
                      onSubmitted: (_) => _run(),
                    ),
                  ),
                ],
              ),
            ),
            _FilterBar(
              filters: _filters,
              years: widget.years,
              onChange: _setFilters,
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (!_searched) {
      return EmptyState(
        icon: Icons.search_rounded,
        title: tr('search_start_title'),
        subtitle: tr('search_start_sub'),
      );
    }
    if (_result.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: tr('search_nothing_title'),
        subtitle: tr('search_nothing_sub'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          WicklyDesign.screenPad, 4, WicklyDesign.screenPad, 24),
      children: [
        if (_result.entries.isNotEmpty) ...[
          _SectionHeader(
            label: tr('search_section_entries'),
            count: _result.entries.length,
          ),
          // Результаты появляются каскадом, а не подменяются рывком: список
          // меняется на каждую букву, и без этого он моргал.
          for (final (i, hit) in _result.entries.indexed)
            Reveal(
              // Ключ включает запрос: новый запрос — новое появление.
              group: _shown,
              id: '${_controller.text}/${hit.entry.id}',
              delay: WicklyDesign.revealDelay(i),
              child: _EntryHitRow(
                  hit: hit, onTap: () => widget.onOpen?.call(hit.entry)),
            ),
        ],
        if (_result.photos.isNotEmpty) ...[
          _SectionHeader(
            label: tr('search_section_photos'),
            count: _result.photos.length,
            icon: Icons.document_scanner_rounded,
          ),
          for (final (i, hit) in _result.photos.indexed)
            Reveal(
              group: _shown,
              id: '${_controller.text}/photo/${hit.media.id}',
              delay: WicklyDesign.revealDelay(i),
              child: _PhotoHitRow(
                  hit: hit, onTap: () => widget.onOpen?.call(hit.entry)),
            ),
        ],
      ],
    );
  }
}

/// Заголовок секции результатов: «ЗАПИСИ · 6».
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final IconData? icon;

  const _SectionHeader({required this.label, required this.count, this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 2, 10),
      child: Row(
        children: [
          Text(
            '${label.toUpperCase()} · $count',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (icon != null) Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Строка найденной записи с подсвеченным совпадением.
class _EntryHitRow extends StatelessWidget {
  final EntryHit hit;
  final VoidCallback? onTap;

  const _EntryHitRow({required this.hit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final e = hit.entry;

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: MediaThumb(coverKey: CoverPalette.forSeed(e.id)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.title?.trim().isNotEmpty == true
                                  ? e.title!
                                  : tr('entry_untitled'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.displayFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (e.mood != null) MoodDot(mood: e.mood, size: 10),
                        ],
                      ),
                      const SizedBox(height: 3),
                      HighlightedText(
                        text: hit.snippet,
                        start: hit.matchStart,
                        length: hit.matchLength,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Dates.dayMonth(e.entryDate),
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11.5,
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
    );
  }
}

/// Строка находки на фотографии (распознанный текст).
class _PhotoHitRow extends StatelessWidget {
  final PhotoHit hit;
  final VoidCallback? onTap;

  const _PhotoHitRow({required this.hit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PressableScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: MediaThumb(
                      media: hit.media,
                      coverKey: CoverPalette.forSeed(hit.media.id),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hit.entry.title?.trim().isNotEmpty == true
                            ? hit.entry.title!
                            : tr('entry_untitled'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      HighlightedText(
                        text: '«${hit.snippet}»',
                        start: hit.matchStart + 1,
                        length: hit.matchLength,
                        italic: true,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('found_on_photo'),
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11.5,
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
    );
  }
}

/// Текст с подсветкой найденного куска.
class HighlightedText extends StatelessWidget {
  final String text;
  final int start;
  final int length;
  final bool italic;

  const HighlightedText({
    super.key,
    required this.text,
    required this.start,
    required this.length,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 13,
      height: 1.35,
      fontStyle: italic ? FontStyle.italic : null,
      color: scheme.onSurfaceVariant,
    );

    if (start < 0 || length <= 0 || start + length > text.length) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: base);
    }

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: text.substring(0, start)),
        TextSpan(
          text: text.substring(start, start + length),
          style: base.copyWith(
            color: scheme.onPrimaryContainer,
            backgroundColor: scheme.primaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: text.substring(start + length)),
      ]),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
  }
}

/// Ряд фильтров под строкой поиска.
class _FilterBar extends StatelessWidget {
  final SearchFilters filters;
  final List<int> years;
  final ValueChanged<SearchFilters> onChange;

  const _FilterBar({
    required this.filters,
    required this.years,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: WicklyDesign.screenPad),
        children: [
          _MoodFilter(
            value: filters.mood,
            onChange: (m) => onChange(m == null
                ? filters.copyWith(clearMood: true)
                : filters.copyWith(mood: m)),
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.star_rounded,
            label: tr('filter_favorite'),
            selected: filters.favorite,
            onTap: () => onChange(filters.copyWith(favorite: !filters.favorite)),
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.image_rounded,
            label: tr('filter_with_photo'),
            selected: filters.withPhoto,
            onTap: () => onChange(filters.copyWith(withPhoto: !filters.withPhoto)),
          ),
          const SizedBox(width: 8),
          for (final year in years) ...[
            _Chip(
              label: '$year',
              selected: filters.year == year,
              onTap: () => onChange(filters.year == year
                  ? filters.copyWith(clearYear: true)
                  : filters.copyWith(year: year)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Фильтр по настроению: тап перебирает ступени по кругу.
class _MoodFilter extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChange;

  const _MoodFilter({required this.value, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return _Chip(
      dotColor: value == null ? null : MoodPaletteX.of(context, value),
      icon: value == null ? Icons.mood_rounded : null,
      label: value == null ? tr('set_mood') : MoodPaletteX.label(value!),
      selected: value != null,
      onTap: () {
        final next = value == null ? 1 : (value! >= 5 ? null : value! + 1);
        onChange(next);
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final Color? dotColor;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    this.icon,
    this.dotColor,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 34,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: icon != null || dotColor != null ? 12 : 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 9,
                    height: 9,
                    decoration:
                        BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                ] else if (icon != null) ...[
                  Icon(icon,
                      size: 14,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
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
