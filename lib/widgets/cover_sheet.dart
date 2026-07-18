import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data/media_repository.dart';
import '../data/media_store.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../services/web_photo_service.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import 'pressable.dart';
import 'sheet_scaffold.dart';

/// Что человек выбрал шапкой записи.
class CoverChoice {
  final CoverMode mode;

  /// Вложение-обложка, если его только что скачали из сети.
  final String? mediaId;

  const CoverChoice(this.mode, {this.mediaId});
}

/// Обложка записи: выключить, взять первое фото или подобрать по теме.
///
/// Подобранный снимок скачивается в дневник и подписывается автором — так
/// обложка открывается без сети и не выдаёт чужую работу за свою.
Future<CoverChoice?> showCoverSheet(
  BuildContext context, {
  required String entryId,
  required CoverMode current,
  required String topic,
  required bool hasOwnPhoto,
}) =>
    showWicklySheet<CoverChoice>(
      context,
      expand: true,
      builder: (_) => _CoverSheet(
        entryId: entryId,
        current: current,
        topic: topic,
        hasOwnPhoto: hasOwnPhoto,
      ),
    );

class _CoverSheet extends StatefulWidget {
  final String entryId;
  final CoverMode current;
  final String topic;
  final bool hasOwnPhoto;

  const _CoverSheet({
    required this.entryId,
    required this.current,
    required this.topic,
    required this.hasOwnPhoto,
  });

  @override
  State<_CoverSheet> createState() => _CoverSheetState();
}

class _CoverSheetState extends State<_CoverSheet> {
  late final TextEditingController _query =
      TextEditingController(text: widget.topic);

  List<WebPhoto> _results = const [];
  bool _searching = false;
  bool _searched = false;
  String? _busyId;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _searched = true;
    });
    final results = await WebPhotoService.search(_query.text);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  /// Скачивает выбранный снимок в дневник и делает его обложкой.
  Future<void> _pick(WebPhoto photo) async {
    setState(() => _busyId = photo.id);
    final bytes = await WebPhotoService.download(photo);
    if (bytes == null) {
      if (mounted) {
        setState(() => _busyId = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('cover_download_failed'))));
      }
      return;
    }

    final name = await MediaStore.instance
        .put(Uint8List.fromList(bytes), ext: 'jpg');
    final media = Media.create(
      entryId: widget.entryId,
      kind: MediaKind.photo,
      file: name,
      // Автор и лицензия едут в подписи: обложка показывает их под собой.
      caption: photo.credit,
      // Порядок ниже нуля, чтобы обложка не лезла в начало галереи записи.
      sort: -1,
    );
    await MediaRepository.instance.insert(media);

    if (mounted) {
      Navigator.of(context).pop(CoverChoice(CoverMode.web, mediaId: media.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SheetScaffold(
      expand: true,
      title: tr('cover'),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: WicklyDesign.screenPad),
        children: [
          _ModeRow(
            icon: Icons.crop_din_rounded,
            title: tr('cover_none'),
            subtitle: tr('cover_none_sub'),
            selected: widget.current == CoverMode.none,
            onTap: () =>
                Navigator.of(context).pop(const CoverChoice(CoverMode.none)),
          ),
          _ModeRow(
            icon: Icons.photo_rounded,
            title: tr('cover_own'),
            subtitle: widget.hasOwnPhoto
                ? tr('cover_own_sub')
                : tr('cover_own_empty'),
            selected: widget.current == CoverMode.auto,
            onTap: widget.hasOwnPhoto
                ? () => Navigator.of(context)
                    .pop(const CoverChoice(CoverMode.auto))
                : null,
          ),

          const SizedBox(height: 18),
          Text(
            tr('cover_by_topic'),
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: tr('cover_topic_hint'),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: _searching ? null : _search,
                child: Text(tr('search')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr('cover_source_note'),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 11.5,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const CoverQuotaBadge(),
          const SizedBox(height: 14),

          if (_searching)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searched && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  tr('cover_nothing_found'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            for (final photo in _results)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WebPhotoTile(
                  photo: photo,
                  busy: _busyId == photo.id,
                  onTap: _busyId == null ? () => _pick(photo) : null,
                ),
              ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Сколько поисков обложки осталось на сегодня.
///
/// Openverse отдаёт остаток в заголовках, но только после первого запроса —
/// до него плашки нет вовсе: пугать числом раньше, чем человек что-то сделал,
/// незачем.
class CoverQuotaBadge extends StatelessWidget {
  const CoverQuotaBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<WebPhotoQuota>(
      valueListenable: WebPhotoService.quota,
      builder: (context, quota, _) {
        if (!quota.known) return const SizedBox.shrink();

        final String text;
        if (quota.exhausted) {
          text = quota.leftToday == 0 || quota.leftThisMinute > 0
              ? tr('cover_quota_exhausted')
              : trf('cover_quota_minute', {'n': quota.leftThisMinute});
        } else if (quota.leftToday >= 0 && quota.perDay > 0) {
          text = trf('cover_quota_left', {
            'n': quota.leftToday,
            'of': quota.perDay,
          });
        } else {
          return const SizedBox.shrink();
        }

        final accent = quota.low ? scheme.error : scheme.onSurfaceVariant;

        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: quota.low
                  ? scheme.errorContainer.withValues(alpha: 0.5)
                  : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  quota.low
                      ? Icons.hourglass_bottom_rounded
                      : Icons.data_usage_rounded,
                  size: 18,
                  color: accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tr('cover_quota_note'),
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 11.5,
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Строка выбора режима обложки.
class _ModeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCover),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: enabled
                              ? (selected
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurface)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 12.5,
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Найденный снимок с именем автора.
class _WebPhotoTile extends StatelessWidget {
  final WebPhoto photo;
  final bool busy;
  final VoidCallback? onTap;

  const _WebPhotoTile({required this.photo, required this.busy, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PressableScale(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WicklyDesign.radiusCover),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.thumbUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) => ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(Icons.broken_image_rounded,
                        color: scheme.onSurfaceVariant),
                  ),
                  loadingBuilder: (context, child, progress) =>
                      progress == null
                          ? child
                          : ColoredBox(color: scheme.surfaceContainerHighest),
                ),
                // Автора показываем прямо на плитке: выбирая снимок, человек
                // сразу видит, чьё имя окажется под обложкой.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                    child: Text(
                      photo.credit.isEmpty ? tr('cover_unknown_author') : photo.credit,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (busy)
                  const ColoredBox(
                    color: Color(0x99000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
