import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/media.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/empty_state.dart';
import '../widgets/media_thumb.dart';
import '../widgets/pressable.dart';
import '../widgets/reveal.dart';

/// Фильтр медиа-сетки.
enum MediaFilter { all, photo, video, audio }

/// Медиа-сетка: все вложения дневника по месяцам.
///
/// Мозаика, а не ровная сетка: крупная плитка держит месяц, мелкие дают ритм.
/// Так галерея за год листается как альбом, а не как таблица.
class MediaView extends StatefulWidget {
  final List<Media> media;

  /// К какой записи ведёт вложение — по нажатию открываем её.
  final void Function(Media media)? onOpen;
  final VoidCallback? onSearch;

  const MediaView({super.key, required this.media, this.onOpen, this.onSearch});

  @override
  State<MediaView> createState() => _MediaViewState();
}

class _MediaViewState extends State<MediaView> {
  MediaFilter _filter = MediaFilter.all;
  final _revealed = <String>{};

  List<Media> get _visible => switch (_filter) {
    MediaFilter.all => widget.media,
    MediaFilter.photo =>
      widget.media
          .where((m) => m.kind == MediaKind.photo || m.kind == MediaKind.sketch)
          .toList(),
    MediaFilter.video =>
      widget.media.where((m) => m.kind == MediaKind.video).toList(),
    MediaFilter.audio =>
      widget.media.where((m) => m.kind == MediaKind.audio).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visible = _visible;
    final months = _groupByMonth(visible);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: tr('search'),
          onPressed: widget.onSearch,
        ),
        title: Text(tr('tab_media')),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: WicklyDesign.screenPad,
              ),
              children: [
                for (final f in MediaFilter.values) ...[
                  _FilterChip(
                    height: 34,
                    label: switch (f) {
                      MediaFilter.all => tr('media_all'),
                      MediaFilter.photo => tr('media_photo'),
                      MediaFilter.video => tr('media_video'),
                      MediaFilter.audio => tr('media_audio'),
                    },
                    selected: _filter == f,
                    onTap: () => setState(() => _filter = f),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    icon: Icons.photo_library_rounded,
                    title: tr('media_empty_title'),
                    subtitle: tr('media_empty_sub'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      WicklyDesign.screenPad,
                      6,
                      WicklyDesign.screenPad,
                      24,
                    ),
                    children: [
                      for (final month in months) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 14, 2, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  Dates.monthYear(month.month),
                                  style: TextStyle(
                                    fontFamily: AppTheme.displayFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                _countLabel(month.items),
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Mosaic(
                          items: month.items,
                          revealed: _revealed,
                          onOpen: widget.onOpen,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _countLabel(List<Media> items) {
    final photos = items
        .where((m) => m.kind == MediaKind.photo || m.kind == MediaKind.sketch)
        .length;
    final videos = items.where((m) => m.kind == MediaKind.video).length;
    return trf('media_count', {'photo': photos, 'video': videos});
  }

  static List<_MonthGroup> _groupByMonth(List<Media> items) {
    final byMonth = <int, List<Media>>{};
    for (final m in items) {
      final d = m.takenAt ?? m.createdAt;
      (byMonth[d.year * 100 + d.month] ??= []).add(m);
    }
    final keys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final k in keys)
        _MonthGroup(month: DateTime(k ~/ 100, k % 100), items: byMonth[k]!),
    ];
  }
}

class _MonthGroup {
  final DateTime month;
  final List<Media> items;
  const _MonthGroup({required this.month, required this.items});
}

/// Мозаика: чередуются «герой» (крупная плитка плюс две мелкие в столбик) и
/// ровный ряд из трёх. Блок всегда занимает три плитки, поэтому в сетке не
/// остаётся дыр, а страница при этом не выглядит таблицей.
class _Mosaic extends StatelessWidget {
  final List<Media> items;
  final Set<String> revealed;
  final void Function(Media)? onOpen;

  const _Mosaic({required this.items, required this.revealed, this.onOpen});

  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final unit = (c.maxWidth - _gap * 2) / 3;
        final blocks = <Widget>[];

        for (var i = 0; i * 3 < items.length; i++) {
          final chunk = items.skip(i * 3).take(3).toList();
          // Каждый третий блок — «герой»; сторона крупной плитки чередуется.
          final hero = i % 3 == 0 && chunk.length == 3;
          blocks.add(
            Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: hero
                  ? _heroBlock(chunk, unit, (i ~/ 3).isEven)
                  : _row(chunk, unit),
            ),
          );
        }
        return Column(children: blocks);
      },
    );
  }

  Widget _tile(Media m, Size size) =>
      _Tile(media: m, size: size, revealed: revealed, onOpen: onOpen);

  Widget _row(List<Media> chunk, double unit) => Row(
    children: [
      for (var i = 0; i < chunk.length; i++) ...[
        _tile(chunk[i], Size(unit, unit)),
        if (i != chunk.length - 1) const SizedBox(width: _gap),
      ],
    ],
  );

  Widget _heroBlock(List<Media> chunk, double unit, bool bigLeft) {
    final big = _tile(chunk.first, Size(unit * 2 + _gap, unit * 2 + _gap));
    final column = Column(
      children: [
        _tile(chunk[1], Size(unit, unit)),
        const SizedBox(height: _gap),
        _tile(chunk[2], Size(unit, unit)),
      ],
    );
    return Row(
      children: bigLeft
          ? [big, const SizedBox(width: _gap), column]
          : [column, const SizedBox(width: _gap), big],
    );
  }
}

/// Одна плитка мозаики.
class _Tile extends StatelessWidget {
  final Media media;
  final Size size;
  final Set<String> revealed;
  final void Function(Media)? onOpen;

  const _Tile({
    required this.media,
    required this.size,
    required this.revealed,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Reveal(
      group: revealed,
      id: media.id,
      child: PressableScale(
        child: GestureDetector(
          onTap: () => onOpen?.call(media),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: MediaThumb(
                media: media,
                coverKey: CoverPalette.forSeed(media.id),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Пилюля фильтра над сеткой.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 34,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
