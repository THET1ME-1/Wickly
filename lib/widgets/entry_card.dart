import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import 'markdown_lite.dart';
import 'media_thumb.dart';
import 'pressable.dart';

/// Запись вместе со всем, что нужно карточке: обложка, счётчик вложений, теги.
///
/// Собирается один раз в ленте, а не подтягивается карточкой по одной —
/// иначе на каждый скролл летит десяток запросов в базу.
class EntryCardItem {
  final Entry entry;
  final Media? cover;
  final int mediaCount;
  final List<String> tags;

  /// Имя дневника записи. Заполняется, только когда дневников больше одного, —
  /// иначе метка «Личное» на каждой карточке лишний шум.
  final String? journalName;

  const EntryCardItem({
    required this.entry,
    this.cover,
    this.mediaCount = 0,
    this.tags = const [],
    this.journalName,
  });
}

/// Карточка записи в ленте.
///
/// Две формы: с обложкой (когда в записи есть фото или видео) и без неё —
/// тогда карточка живёт текстом и пилюлями контекста. Так лента дышит и не
/// превращается в ровный список одинаковых плашек.
class EntryCard extends StatelessWidget {
  final EntryCardItem item;
  final VoidCallback? onTap;

  const EntryCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    final scheme = Theme.of(context).colorScheme;
    final hasCover = item.cover != null;
    final snippet = MarkdownLite.strip(e.body);

    return PressableScale(
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCover) _cover(context),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    WicklyDesign.gapInside,
                    hasCover ? 12 : WicklyDesign.gapInside,
                    WicklyDesign.gapInside,
                    WicklyDesign.gapInside),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Из какого дневника запись — когда их несколько. Над
                    // заголовком, чтобы читалось и на карточке с обложкой.
                    if (item.journalName != null) ...[
                      Row(
                        children: [
                          Icon(Icons.menu_book_rounded,
                              size: 13, color: scheme.primary),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              item.journalName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _title(e),
                            // Три строки: заголовок записи — главное, что
                            // человек ищет глазами в ленте.
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppTheme.displayFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        if (e.pinned) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.push_pin_rounded,
                              size: 15, color: scheme.primary),
                        ],
                        // Без обложки метку настроения ставим у заголовка,
                        // с обложкой она уже нарисована поверх картинки.
                        if (!hasCover && e.mood != null) ...[
                          const SizedBox(width: 8),
                          MoodDot(mood: e.mood, size: 13),
                        ],
                      ],
                    ),
                    if (snippet.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        snippet,
                        maxLines: hasCover ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13.5,
                          height: 1.4,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (!hasCover) ...[
                      const SizedBox(height: 10),
                      _chips(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Обложка со временем слева и настроением справа.
  Widget _cover(BuildContext context) {
    final e = item.entry;
    return SizedBox(
      height: WicklyDesign.feedCoverHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaThumb(
            media: item.cover,
            coverKey: CoverPalette.forSeed(e.id),
          ),
          // Тёмная вуаль сверху и снизу, чтобы белые метки читались на любом фото.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x4D000000), Color(0x00000000), Color(0x33000000)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _Badge(label: Dates.time(e.entryDate)),
          ),
          if (e.mood != null)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0x59000000),
                  shape: BoxShape.circle,
                ),
                child: MoodDot(mood: e.mood, size: 14),
              ),
            ),
          if (item.mediaCount > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: _Badge(label: '+${item.mediaCount - 1}'),
            ),
        ],
      ),
    );
  }

  /// Пилюли контекста у карточки без обложки: время, место, первый тег.
  Widget _chips(BuildContext context) {
    final e = item.entry;
    final scheme = Theme.of(context).colorScheme;

    TextStyle style() => TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        );

    Widget pill(Widget child) => Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [child]),
        );

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        pill(Text(Dates.time(e.entryDate), style: style())),
        if (e.place != null)
          pill(Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.place_rounded, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(e.place!,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: style()),
            ),
          ])),
        if (item.tags.isNotEmpty) pill(Text('#${item.tags.first}', style: style())),
        if (item.mediaCount > 0)
          pill(Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.image_rounded, size: 13, color: scheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('${item.mediaCount}', style: style()),
          ])),
      ],
    );
  }

  /// Короткая выжимка текста записи — для карточек воспоминаний и поиска.
  static String previewOf(Entry e) {
    final body = MarkdownLite.strip(e.body);
    if (body.isEmpty) return tr('entry_untitled');
    return body.length <= 90 ? body : '${body.substring(0, 90)}…';
  }

  static String _title(Entry e) {
    final t = e.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final body = MarkdownLite.strip(e.body);
    if (body.isNotEmpty) {
      return body.length <= 42 ? body : '${body.substring(0, 42)}…';
    }
    return tr('entry_untitled');
  }
}

/// Тёмная метка поверх обложки (время, «+5»).
class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x59000000),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
