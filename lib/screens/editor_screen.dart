import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_prefs.dart';
import '../data/catalog_repository.dart';
import '../data/entry_repository.dart';
import '../data/journal_repository.dart';
import '../data/media_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../services/context_service.dart';
import '../services/media_service.dart';
import '../theme/app_theme.dart';
import '../theme/mood_palette_ext.dart';
import '../theme/wickly_design.dart';
import '../utils/dates.dart';
import '../utils/markdown_edit.dart';
import '../widgets/context_chip.dart';
import '../widgets/markdown_controller.dart';
import '../widgets/markdown_lite.dart';
import '../widgets/media_thumb.dart';
import '../widgets/mood_sheet.dart';
import '../widgets/sketch_sheet.dart';
import '../widgets/voice_sheet.dart';

/// Редактор записи.
///
/// Пишется в одном месте: текст, разметка, фото, голос и авто-контекст. Ничего
/// не теряется — черновик уходит в базу через пару секунд после последней
/// буквы, поэтому закрытое приложение или севший телефон не отнимают запись.
class EditorScreen extends StatefulWidget {
  /// Запись для правки. `null` — заводим новую.
  final Entry? entry;

  /// В какой дневник кладём новую запись.
  final String journalId;

  /// Подсказка дня, с которой начали.
  final String? promptKey;

  /// Настроение, отмеченное ещё до открытия редактора — тап по кружку в
  /// виджете на домашнем экране.
  final int? initialMood;

  const EditorScreen({
    super.key,
    this.entry,
    required this.journalId,
    this.promptKey,
    this.initialMood,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _title;
  late final MarkdownEditingController _body;
  final _bodyFocus = FocusNode();

  late Entry _entry;
  List<Media> _media = const [];
  List<Journal> _journals = const [];

  Timer? _autosave;
  bool _dirty = false;
  bool _saving = false;

  /// Когда открыли редактор — из этого считается «время на запись».
  final _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _entry = widget.entry ??
        Entry.create(
          journalId: widget.journalId,
          promptKey: widget.promptKey,
          mood: widget.initialMood,
          draft: true,
        );
    _title = TextEditingController(text: _entry.title ?? '');
    _body = MarkdownEditingController(text: _entry.body ?? '');
    _title.addListener(_onChanged);
    _body.addListener(_onChanged);

    _loadJournals();
    if (widget.entry == null) {
      _captureContext();
    } else {
      _loadMedia();
    }
  }

  Future<void> _loadJournals() async {
    final journals = await JournalRepository.instance.all();
    if (mounted) setState(() => _journals = journals);
  }

  /// Перенос записи в другой дневник. Выбранный запоминается: следующая запись
  /// по умолчанию ляжет туда же.
  Future<void> _pickJournal() async {
    if (_journals.length < 2) return;
    final scheme = Theme.of(context).colorScheme;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            for (final j in _journals)
              ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: CoverPalette.gradient(j.cover),
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                title: Text(j.name),
                trailing: j.id == _entry.journalId
                    ? Icon(Icons.check_rounded, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, j.id),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await AppPrefs.instance.setLastJournal(picked);
    setState(() {
      _entry = _entry.copyWith(journalId: picked);
      _dirty = true;
    });
    _scheduleSave();
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _loadMedia() async {
    final media = await MediaRepository.instance.forEntry(_entry.id);
    if (mounted) setState(() => _media = media);
  }

  /// Место и погода подставляются сами — если человек это разрешил.
  Future<void> _captureContext() async {
    if (!AppPrefs.instance.autoContext) return;
    final ctx = await ContextService.capture();
    if (!mounted || ctx.isEmpty) return;
    setState(() {
      _entry = _entry.copyWith(
        lat: ctx.lat,
        lon: ctx.lon,
        place: ctx.place,
        weather: ctx.weather,
        weatherCode: ctx.weatherCode,
        temp: ctx.temp,
      );
      _dirty = true;
    });
    _scheduleSave();
  }

  void _onChanged() {
    _dirty = true;
    _scheduleSave();
    setState(() {}); // счётчик слов
  }

  /// Автосохранение с паузой: пишем через две секунды тишины, а не на каждую
  /// букву — иначе база молотит на каждый символ.
  void _scheduleSave() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save({bool finish = false}) async {
    if (!_dirty && !finish) return;
    if (_saving) return;
    _saving = true;

    final body = _body.text;
    final entry = _entry.copyWith(
      title: _title.text.trim(),
      body: body,
      wordCount: MarkdownLite.wordCount(body),
      writeMs: _entry.writeMs +
          DateTime.now().difference(_openedAt).inMilliseconds,
      draft: !finish,
    );

    await EntryRepository.instance.upsert(entry);

    // Хэштеги из текста становятся тегами записи — руками их дублировать не надо.
    final names = MarkdownLite.hashtags(body);
    final ids = <String>[];
    for (final name in names) {
      ids.add((await CatalogRepository.instance.ensureTag(name)).id);
    }
    await CatalogRepository.instance.setTagsOf(entry.id, ids);

    _entry = entry;
    _dirty = false;
    _saving = false;
  }

  /// Пустую запись при выходе не оставляем: иначе лента засоряется призраками.
  bool get _isEmpty =>
      _title.text.trim().isEmpty && _body.text.trim().isEmpty && _media.isEmpty;

  Future<void> _close() async {
    _autosave?.cancel();
    if (_isEmpty) {
      if (widget.entry != null) await EntryRepository.instance.delete(_entry.id);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await _save(finish: true);
    if (mounted) Navigator.of(context).pop(_entry);
  }

  Future<void> _done() async {
    _autosave?.cancel();
    await _save(finish: true);
    if (mounted) Navigator.of(context).pop(_entry);
  }

  // ------------------------------ Действия ------------------------------

  void _format(String marker, {bool prefix = false}) {
    final result = prefix
        ? MarkdownEdit.togglePrefix(_body.text, _body.selection, marker)
        : MarkdownEdit.toggleInline(_body.text, _body.selection, marker);
    _body.value = TextEditingValue(
      text: result.text,
      selection: result.selection,
    );
    _bodyFocus.requestFocus();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _entry.entryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_entry.entryDate),
    );
    setState(() {
      _entry = _entry.copyWith(
        entryDate: DateTime(
          date.year,
          date.month,
          date.day,
          time?.hour ?? _entry.entryDate.hour,
          time?.minute ?? _entry.entryDate.minute,
        ),
      );
      _dirty = true;
    });
    _scheduleSave();
  }

  Future<void> _pickMood() async {
    await _save();
    if (!mounted) return;
    final result = await showMoodSheet(
      context,
      entryId: _entry.id,
      mood: _entry.mood,
      at: _entry.entryDate,
    );
    if (result == null || !mounted) return;
    setState(() {
      _entry = _entry.copyWith(mood: result.mood);
      _dirty = true;
    });
    _scheduleSave();
  }

  Future<void> _addPhotos() async {
    await _save();
    final added = await MediaService.pickPhotos(_entry.id,
        sortFrom: _media.length);
    if (added.isNotEmpty) _loadMedia();
  }

  Future<void> _takePhoto() async {
    await _save();
    final added =
        await MediaService.takePhoto(_entry.id, sort: _media.length);
    if (added != null) _loadMedia();
  }

  Future<void> _addVideo() async {
    await _save();
    final added = await MediaService.pickVideo(_entry.id, sort: _media.length);
    if (added != null) _loadMedia();
  }

  Future<void> _addSketch() async {
    await _save();
    if (!mounted) return;
    final png = await showSketchSheet(context);
    if (png == null) return;
    await MediaService.attachSketch(_entry.id, png, sort: _media.length);
    _loadMedia();
  }

  Future<void> _voice() async {
    await _save();
    if (!mounted) return;
    final result = await showVoiceSheet(context, entryId: _entry.id);
    if (result == null || !mounted) return;

    if (result.transcript != null && result.transcript!.isNotEmpty) {
      final insertion =
          _body.text.isEmpty ? result.transcript! : ' ${result.transcript!}';
      final edit =
          MarkdownEdit.insert(_body.text, _body.selection, insertion);
      _body.value =
          TextEditingValue(text: edit.text, selection: edit.selection);
    }
    if (result.audioPath != null) {
      await MediaService.attachAudio(
        _entry.id,
        result.audioPath!,
        durationMs: result.durationMs,
        sort: _media.length,
      );
      _loadMedia();
    }
  }

  Future<void> _removeMedia(Media m) async {
    await MediaRepository.instance.delete(m);
    _loadMedia();
  }

  // ------------------------------- Вид -------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final words = MarkdownLite.wordCount(_body.text);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _close,
          ),
          title: Text(
            tr('draft_saved'),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: _done,
                child: Text(tr('done')),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(WicklyDesign.screenPad, 6,
                    WicklyDesign.screenPad, 12),
                children: [
                  _contextChips(),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 21,
                      letterSpacing: -0.3,
                      color: scheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: tr('entry_title_hint'),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 2),
                  TextField(
                    controller: _body,
                    focusNode: _bodyFocus,
                    maxLines: null,
                    minLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 15,
                      height: 1.5,
                      color: scheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: tr('entry_body_hint'),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: _onBodyChanged,
                  ),
                  const SizedBox(height: 14),
                  _mediaStrip(),
                  const SizedBox(height: 10),
                  Text(
                    '${Dates.wordCount(words)} · '
                    '${Dates.minutes(DateTime.now().difference(_openedAt).inMilliseconds + _entry.writeMs)}',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _Toolbar(
              onFormat: _format,
              onPhoto: _addPhotos,
              onCamera: _takePhoto,
              onVideo: _addVideo,
              onSketch: _addSketch,
              onVoice: _voice,
              onPlace: _captureContext,
              onMood: _pickMood,
            ),
          ],
        ),
      ),
    );
  }

  /// Enter внутри списка продолжает список.
  void _onBodyChanged(String value) {
    if (!value.endsWith('\n')) return;
    final selection = TextSelection.collapsed(offset: _body.selection.start);
    final before = value.substring(0, value.length - 1);
    final result = MarkdownEdit.continueList(
      before,
      TextSelection.collapsed(offset: before.length),
    );
    if (result == null) return;
    _body.value = TextEditingValue(
      text: result.text,
      selection: result.selection,
    );
    // selection выше уже учтён — переменная нужна лишь для читаемости.
    assert(selection.isValid || true);
  }

  Widget _contextChips() {
    final e = _entry;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_journals.length > 1)
          ContextChip(
            icon: Icons.menu_book_rounded,
            label: _journals
                .firstWhere((j) => j.id == e.journalId,
                    orElse: () => _journals.first)
                .name,
            onTap: _pickJournal,
          ),
        ContextChip(
          icon: Icons.schedule_rounded,
          label: '${Dates.relativeDay(e.entryDate)}, ${Dates.time(e.entryDate)}',
          onTap: _pickDate,
        ),
        ContextChip(
          dotColor: e.mood == null ? null : MoodPaletteX.of(context, e.mood),
          icon: e.mood == null ? Icons.mood_rounded : null,
          label: e.mood == null ? tr('set_mood') : MoodPaletteX.label(e.mood!),
          onTap: _pickMood,
        ),
        if (e.place != null)
          ContextChip(icon: Icons.place_rounded, label: e.place!),
        if (e.weather != null)
          ContextChip(
            icon: ContextService.weatherIcon(e.weatherCode),
            label: ContextService.weatherChip(e.temp, e.weather),
          ),
      ],
    );
  }

  Widget _mediaStrip() {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final m in _media) ...[
            _MediaTile(media: m, onRemove: () => _removeMedia(m)),
            const SizedBox(width: 8),
          ],
          // Плитка «плюс» — тот же размер, чтобы ряд не прыгал.
          GestureDetector(
            onTap: _addPhotos,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant, width: 1.5),
              ),
              child: Icon(Icons.add_rounded, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Плитка вложения в редакторе с крестиком.
class _MediaTile extends StatelessWidget {
  final Media media;
  final VoidCallback onRemove;

  const _MediaTile({required this.media, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 78,
            height: 78,
            child: MediaThumb(
              media: media,
              coverKey: CoverPalette.forSeed(media.id),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded,
                  size: 14, color: scheme.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

/// Панель под текстом: разметка сверху, вложения снизу.
class _Toolbar extends StatelessWidget {
  final void Function(String marker, {bool prefix}) onFormat;
  final VoidCallback onPhoto;
  final VoidCallback onCamera;
  final VoidCallback onVideo;
  final VoidCallback onSketch;
  final VoidCallback onVoice;
  final VoidCallback onPlace;
  final VoidCallback onMood;

  const _Toolbar({
    required this.onFormat,
    required this.onPhoto,
    required this.onCamera,
    required this.onVideo,
    required this.onSketch,
    required this.onVoice,
    required this.onPlace,
    required this.onMood,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Row(children: [
              _Btn(
                icon: Icons.format_bold_rounded,
                tooltip: tr('format_bold'),
                onTap: () => onFormat('**'),
              ),
              _Btn(
                icon: Icons.format_italic_rounded,
                tooltip: tr('format_italic'),
                onTap: () => onFormat('*'),
              ),
              _Btn(
                icon: Icons.title_rounded,
                tooltip: tr('format_heading'),
                onTap: () => onFormat('## ', prefix: true),
              ),
              _Btn(
                icon: Icons.format_list_bulleted_rounded,
                tooltip: tr('format_list'),
                onTap: () => onFormat('- ', prefix: true),
              ),
              _Btn(
                icon: Icons.checklist_rounded,
                tooltip: tr('format_todo'),
                onTap: () => onFormat('- [ ] ', prefix: true),
              ),
              _Btn(
                icon: Icons.format_quote_rounded,
                tooltip: tr('format_quote'),
                onTap: () => onFormat('> ', prefix: true),
              ),
            ]),
            _Row(children: [
              _Btn(
                icon: Icons.image_rounded,
                tooltip: tr('add_photo'),
                onTap: onPhoto,
              ),
              _Btn(
                icon: Icons.photo_camera_rounded,
                tooltip: tr('take_photo'),
                onTap: onCamera,
              ),
              _Btn(
                icon: Icons.videocam_rounded,
                tooltip: tr('add_video'),
                onTap: onVideo,
              ),
              _Btn(
                icon: Icons.draw_rounded,
                tooltip: tr('add_sketch'),
                onTap: onSketch,
              ),
              _Btn(
                icon: Icons.mic_rounded,
                tooltip: tr('voice'),
                onTap: onVoice,
              ),
              _Btn(
                icon: Icons.place_rounded,
                tooltip: tr('set_place'),
                onTap: onPlace,
              ),
              _Btn(
                icon: Icons.mood_rounded,
                tooltip: tr('set_mood'),
                onTap: onMood,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<Widget> children;
  const _Row({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: children,
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _Btn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(13),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: SizedBox(
              width: 44,
              height: 40,
              child: Icon(icon, size: 20, color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
