import 'package:flutter/material.dart';

import '../theme/feedback.dart';
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
import '../widgets/media_grid.dart';
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
    Haptics.commit();
    final e = _entry;
    if (e == null) return;
    final updated = e.copyWith(favorite: !e.favorite);
    await EntryRepository.instance.update(updated);
    setState(() => _entry = updated);
  }

  /// Отметка пункта чеклиста прямо в читалке.
  Future<void> _toggleTodo(String newBody) async {
    Haptics.tap();
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
        Haptics.commit();
        final updated = e.copyWith(pinned: !e.pinned);
        await EntryRepository.instance.update(updated);
        setState(() => _entry = updated);
      case 'hide':
        Haptics.commit();
        final updated = e.copyWith(hidden: !e.hidden);
        await EntryRepository.instance.update(updated);
        setState(() => _entry = updated);
      case 'delete':
        Haptics.warn();
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
    // Обложка: выключена, своё фото или подобранный снимок.
    final chosen = e.coverMediaId == null
        ? null
        : _media.where((m) => m.id == e.coverMediaId).firstOrNull;
    final cover = switch (e.coverMode) {
      CoverMode.none => null,
      CoverMode.web || CoverMode.own => chosen,
      CoverMode.auto => chosen ?? _media.where((m) => m.isVisual).firstOrNull,
    };
    final byId = {for (final m in _media) m.id: m};
    // Вложения, которых нет в тексте (пришли из старых записей или из синка),
    // показываем в конце — молча терять их нельзя.
    final referenced = MarkdownLite.parse(e.body ?? '')
        .where((b) => b.kind == MdBlockKind.media)
        .map((b) => b.mediaId)
        .toSet();
    // Обложку из сети в галерею не пускаем: она шапка, а не вложение записи.
    final loose = _media
        .where((m) => !referenced.contains(m.id) && m.id != e.coverMediaId)
        .toList();
    final looseVisual = loose.where((m) => m.kind != MediaKind.audio).toList();
    final looseAudio = loose.where((m) => m.kind == MediaKind.audio).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _CoverBar(
            entry: e,
            cover: cover,
            onMenu: _menu,
            onEdit: () async {
              await widget.onEdit?.call(e);
              await _load();
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 16,
                  WicklyDesign.screenPad, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cover == null) ...[
                    Text(
                      '${Dates.dayLong(e.entryDate)} · '
                      '${Dates.time(e.entryDate)}',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
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
                      cards: true,
                      onToggleTodo: _toggleTodo,
                      media: byId,
                      onOpenMedia: (group, index) =>
                          showMediaViewer(context, group, index),
                    ),
                  if (looseVisual.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    MediaGrid(
                      media: looseVisual,
                      onOpen: (i) =>
                          showMediaViewer(context, looseVisual, i),
                    ),
                  ],
                  if (looseAudio.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final a in looseAudio)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AudioPlayerBar(media: a),
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
  final VoidCallback onEdit;

  const _CoverBar({
    required this.entry,
    this.cover,
    required this.onMenu,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = entry.title?.trim();
    final credit = cover?.caption;

    // Без обложки шапка обычная: заголовок и дата уезжают в текст, а сверху
    // остаются только кнопки.
    if (cover == null) {
      return SliverAppBar(
        pinned: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        title: Text(
          title == null || title.isEmpty ? tr('entry_untitled') : title,
          // Без обложки это единственное место, где виден заголовок целиком.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.displayFont,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
            color: scheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: tr('edit'),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: onMenu,
          ),
          const SizedBox(width: 4),
        ],
      );
    }

    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      backgroundColor: scheme.surface,
      foregroundColor: Colors.white,
      leading: const _RoundIconButton(icon: Icons.arrow_back_rounded),
      actions: [
        // Правка левее меню: за ней тянутся чаще, чем за тремя точками.
        _RoundIconButton(icon: Icons.edit_rounded, onTap: onEdit),
        const SizedBox(width: 6),
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
                  // Имя автора под подобранным снимком: чужая работа должна
                  // быть подписана, этого требуют и лицензии, и приличия.
                  if (entry.coverMode == CoverMode.web &&
                      credit != null &&
                      credit.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        credit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11,
                          color: Color(0x99FFFFFF),
                        ),
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
