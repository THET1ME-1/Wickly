import 'package:flutter/material.dart';

import '../data/catalog_repository.dart';
import '../data/entry_repository.dart';
import '../data/media_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../services/context_service.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/context_chip.dart';
import '../widgets/markdown_lite.dart';
import '../widgets/media_thumb.dart';
import '../widgets/media_viewer.dart';
import '../widgets/pressable.dart';

/// Читалка записи — разворот в книге.
///
/// Обложка во всю ширину, под ней авто-контекст, текст, галерея и теги. Здесь
/// ничего не редактируется, кроме чеклиста: отметить пункт хочется прямо при
/// чтении, а лезть за этим в редактор — лишний шаг.
class ReaderScreen extends StatefulWidget {
  final String entryId;

  /// Открыть редактор этой записи.
  final Future<void> Function(Entry entry)? onEdit;

  const ReaderScreen({super.key, required this.entryId, this.onEdit});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  Entry? _entry;
  List<Media> _media = const [];
  List<String> _tags = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entry = await EntryRepository.instance.getById(widget.entryId);
    final media = await MediaRepository.instance.forEntry(widget.entryId);
    final tagIds =
        await CatalogRepository.instance.tagIdsOf(widget.entryId);
    final allTags = await CatalogRepository.instance.tags();
    if (!mounted) return;
    setState(() {
      _entry = entry;
      _media = media;
      _tags = [
        for (final t in allTags)
          if (tagIds.contains(t.id)) t.name,
      ];
    });
  }

  Future<void> _toggleFavorite() async {
    final e = _entry;
    if (e == null) return;
    final updated = e.copyWith(favorite: !e.favorite);
    await EntryRepository.instance.update(updated);
    setState(() => _entry = updated);
  }

  /// Отметка пункта чеклиста прямо в читалке.
  Future<void> _toggleTodo(String newBody) async {
    final e = _entry;
    if (e == null) return;
    final updated = e.copyWith(body: newBody);
    await EntryRepository.instance.update(updated);
    setState(() => _entry = updated);
  }

  Future<void> _menu() async {
    final e = _entry;
    if (e == null) return;
    final scheme = Theme.of(context).colorScheme;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: Text(tr('edit')),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(
                e.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              ),
              title: Text(e.pinned ? tr('unpin_entry') : tr('pin_entry')),
              onTap: () => Navigator.pop(ctx, 'pin'),
            ),
            ListTile(
              leading: Icon(
                e.hidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              ),
              title: Text(e.hidden ? tr('unhide_entry') : tr('hide_entry')),
              onTap: () => Navigator.pop(ctx, 'hide'),
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: scheme.error),
              title: Text(tr('delete'), style: TextStyle(color: scheme.error)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case 'edit':
        await widget.onEdit?.call(e);
        await _load();
      case 'pin':
        final updated = e.copyWith(pinned: !e.pinned);
        await EntryRepository.instance.update(updated);
        setState(() => _entry = updated);
      case 'hide':
        final updated = e.copyWith(hidden: !e.hidden);
        await EntryRepository.instance.update(updated);
        setState(() => _entry = updated);
      case 'delete':
        await EntryRepository.instance.delete(e.id);
        if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = _entry;
    if (e == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final scheme = Theme.of(context).colorScheme;
    final cover = _media.where((m) => m.isVisual).firstOrNull;
    final gallery = _media.where((m) => m.isVisual).toList();
    final audio = _media.where((m) => m.kind == MediaKind.audio).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _CoverBar(entry: e, cover: cover, onMenu: _menu),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 16,
                  WicklyDesign.screenPad, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (e.place != null)
                        ContextChip(icon: Icons.place_rounded, label: e.place!),
                      if (e.weather != null)
                        ContextChip(
                          icon: ContextService.weatherIcon(e.weatherCode),
                          label:
                              ContextService.weatherChip(e.temp, e.weather),
                        ),
                      if (e.mood != null)
                        ContextChip(
                          dotColor: MoodPaletteX.of(context, e.mood),
                          label: MoodPaletteX.label(e.mood!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if ((e.body ?? '').trim().isNotEmpty)
                    MarkdownBody(
                      source: e.body!,
                      onToggleTodo: _toggleTodo,
                    ),
                  if (audio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final a in audio)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AudioPlayerBar(media: a),
                      ),
                  ],
                  if (gallery.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _Gallery(
                      media: gallery,
                      onOpen: (i) => showMediaViewer(context, gallery, i),
                    ),
                  ],
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in _tags)
                          ContextChip(
                              icon: Icons.sell_rounded, label: '#$t'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      PressableScale(
                        child: GestureDetector(
                          onTap: _toggleFavorite,
                          child: Row(
                            children: [
                              Icon(
                                e.favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 18,
                                color: e.favorite
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                e.favorite
                                    ? tr('in_favorites')
                                    : tr('add_to_favorites'),
                                style: TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: e.favorite
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Dates.wordCount(
                            e.wordCount > 0
                                ? e.wordCount
                                : MarkdownLite.wordCount(e.body)),
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка-обложка: фото, заголовок и дата поверх него.
class _CoverBar extends StatelessWidget {
  final Entry entry;
  final Media? cover;
  final VoidCallback onMenu;

  const _CoverBar({required this.entry, this.cover, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = entry.title?.trim();

    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      backgroundColor: scheme.surface,
      foregroundColor: Colors.white,
      leading: const _RoundIconButton(icon: Icons.arrow_back_rounded),
      actions: [
        _RoundIconButton(icon: Icons.more_vert_rounded, onTap: onMenu),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            MediaThumb(
              media: cover,
              coverKey: CoverPalette.forSeed(entry.id),
              showKindBadge: false,
            ),
            // Затемнение снизу: белый заголовок должен читаться на любом фото.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x00000000), Color(0xB3000000)],
                  stops: [0, 0.4, 1],
                ),
              ),
            ),
            Positioned(
              left: WicklyDesign.screenPad,
              right: WicklyDesign.screenPad,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title == null || title.isEmpty
                        ? tr('entry_untitled')
                        : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${Dates.dayLong(entry.entryDate)} · '
                    '${Dates.time(entry.entryDate)}',
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      color: Color(0xE6FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Круглая кнопка поверх обложки — иначе иконка теряется на светлом фото.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: const Color(0x59000000),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? () => Navigator.of(context).maybePop(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Галерея записи: крупный кадр и мелкие рядом, «+N» на последнем.
class _Gallery extends StatelessWidget {
  final List<Media> media;
  final ValueChanged<int> onOpen;

  const _Gallery({required this.media, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (media.length == 1) {
      return _tile(media.first, 0, height: 220, width: double.infinity);
    }

    return LayoutBuilder(builder: (context, c) {
      const gap = 8.0;
      final smallSide = (c.maxWidth - gap * 2) / 3;
      final bigSide = smallSide * 2 + gap;
      final rest = media.skip(1).take(2).toList();
      final hidden = media.length - 3;

      return SizedBox(
        height: bigSide,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tile(media.first, 0, height: bigSide, width: bigSide),
            const SizedBox(width: gap),
            Column(
              children: [
                for (var i = 0; i < rest.length; i++) ...[
                  _tile(
                    rest[i],
                    i + 1,
                    height: smallSide,
                    width: smallSide,
                    more: i == rest.length - 1 && hidden > 0 ? hidden : null,
                  ),
                  if (i == 0) const SizedBox(height: gap),
                ],
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _tile(
    Media m,
    int index, {
    required double height,
    required double width,
    int? more,
  }) =>
      PressableScale(
        child: GestureDetector(
          onTap: () => onOpen(index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MediaThumb(
                    media: m,
                    coverKey: CoverPalette.forSeed(m.id),
                  ),
                  if (more != null)
                    Container(
                      color: const Color(0x8C000000),
                      alignment: Alignment.center,
                      child: Text(
                        '+$more',
                        style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
