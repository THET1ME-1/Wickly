import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/media_store.dart';
import '../l10n/strings.dart';
import '../models/media.dart';
import '../services/media_export.dart';
import '../theme/app_theme.dart';
import '../theme/feedback.dart';
import '../utils/dates.dart';

/// Полноэкранный просмотр вложений с листанием и зумом.
Future<void> showMediaViewer(
  BuildContext context,
  List<Media> media,
  int initialIndex,
) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _MediaViewer(media: media, initialIndex: initialIndex),
      ),
    );

class _MediaViewer extends StatefulWidget {
  final List<Media> media;
  final int initialIndex;

  const _MediaViewer({required this.media, required this.initialIndex});

  @override
  State<_MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<_MediaViewer> {
  late final PageController _pages =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  /// Идёт сохранение. Пока идёт — кнопка не отвечает: два подряд нажатия
  /// клали в галерею две копии одного снимка.
  bool _saving = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await MediaExport.saveToDevice(widget.media[_index]);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result == SaveResult.cancelled) return;
    if (result == SaveResult.saved) Haptics.commit();
    final message = switch (result) {
      SaveResult.saved => Platform.isAndroid || Platform.isIOS
          ? tr('media_saved_gallery')
          : tr('media_saved_file'),
      SaveResult.denied => tr('media_save_denied'),
      _ => tr('media_save_failed'),
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _share() async {
    final ok = await MediaExport.share(widget.media[_index]);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('media_save_failed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.media[_index];
    final caption = current.caption;
    final taken = current.takenAt;

    return Scaffold(
      // Просмотр всегда тёмный: так фото читается одинаково в любой теме.
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          '${_index + 1} / ${widget.media.length}',
          style: const TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: tr('media_save'),
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: tr('share_entry'),
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: widget.media.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => _Page(media: widget.media[i]),
          ),
          if (caption != null || taken != null || current.place != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 34),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xCC000000)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (caption != null)
                      Text(
                        caption,
                        style: const TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    // EXIF-подпись: где и когда снято.
                    if (taken != null || current.place != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (taken != null)
                              '${Dates.full(taken)}, ${Dates.time(taken)}',
                            ?current.place,
                          ].join(' · '),
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 12,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
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

/// Одна страница просмотра: картинка с зумом или видео с плеером.
class _Page extends StatefulWidget {
  final Media media;
  const _Page({required this.media});

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  Uint8List? _bytes;
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (widget.media.kind == MediaKind.video) {
      final path = await MediaStore.instance.materialize(widget.media.file);
      if (path == null || !mounted) return;
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _video = controller);
      await controller.play();
      return;
    }
    final bytes = await MediaStore.instance.read(widget.media.file);
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    if (video != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: video.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(video),
              GestureDetector(
                onTap: () => setState(() =>
                    video.value.isPlaying ? video.pause() : video.play()),
                child: AnimatedOpacity(
                  opacity: video.value.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.play_arrow_rounded,
                      size: 64, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_bytes == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: Center(child: Image.memory(_bytes!)),
    );
  }
}
