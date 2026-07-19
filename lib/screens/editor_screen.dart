import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/feedback.dart';
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
import '../widgets/audio_player_bar.dart';
import '../widgets/context_chip.dart';
import '../widgets/cover_sheet.dart';
import '../widgets/journal_gate.dart';
import '../widgets/markdown_controller.dart';
import '../widgets/media_grid.dart';
import '../widgets/media_viewer.dart';
import 'editor_blocks.dart';
import '../widgets/markdown_lite.dart';
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

  /// Каким днём датировать новую запись — из календаря.
  final DateTime? initialDate;

  const EditorScreen({
    super.key,
    this.entry,
    required this.journalId,
    this.promptKey,
    this.initialMood,
    this.initialDate,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _title;

  /// Запись как лента блоков: абзацы текста и сетки вложений между ними.
  late List<EditorBlock> _blocks;

  /// Куда писать и что форматировать — последний текстовый блок в фокусе.
  TextBlock? _active;

  late Entry _entry;
  List<Media> _media = const [];
  Map<String, Media> _mediaById = const {};
  List<Journal> _journals = const [];

  Timer? _autosave;
  bool _dirty = false;
  bool _saving = false;

  /// До какого момента время уже засчитано в `writeMs`. Двигается на каждом
  /// сохранении, иначе один и тот же промежуток прибавляется многократно.
  DateTime _countedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _entry = widget.entry ??
        Entry.create(
          journalId: widget.journalId,
          promptKey: widget.promptKey,
          mood: widget.initialMood,
          entryDate: widget.initialDate,
          draft: true,
        ).copyWith(
          coverMode: AppPrefs.instance.coverBanner
              ? CoverMode.auto
              : CoverMode.none,
        );
    _title = TextEditingController(text: _entry.title ?? '');
    _title.addListener(_onChanged);
    _blocks = EditorDocument.parse(_entry.body);
    EditorDocument.applyTimes(
      _blocks,
      _entry.blockTimes,
      fallback: _entry.entryDate,
    );
    for (final b in _blocks) {
      if (b is TextBlock) _watch(b);
    }
    _active = _blocks.whereType<TextBlock>().firstOrNull;

    _loadJournals();
    if (widget.entry == null) {
      _captureContext();
    } else {
      _loadMedia(adopt: true);
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
    // В запертый дневник тоже по паролю: иначе запись уезжала бы туда, откуда
    // её потом не достать — она сразу уходит под замок.
    final target = _journals.firstWhere((j) => j.id == picked);
    if (!await openJournalGate(context, target)) return;
    if (!mounted) return;
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
    for (final b in _blocks) {
      if (b is TextBlock) b.dispose();
    }
    super.dispose();
  }

  /// Каждый текстовый блок сам сообщает о правках и о том, что он в фокусе.
  void _watch(TextBlock block) {
    block.controller.addListener(_onChanged);
    block.title.addListener(_onChanged);
    block.focus.addListener(() {
      if (block.focus.hasFocus) _active = block;
    });
  }

  /// Текст записи целиком — из него считаются слова, теги и превью.
  String get _bodyText => EditorDocument.serialize(_blocks);

  TextBlock _newTextBlock([String text = '']) {
    final block = TextBlock(text: text, createdAt: DateTime.now());
    _watch(block);
    return block;
  }

  Future<void> _loadMedia({bool adopt = false}) async {
    final media = await MediaRepository.instance.forEntry(_entry.id);
    if (!mounted) return;
    setState(() {
      _media = media;
      _mediaById = {for (final m in media) m.id: m};
      if (adopt) _adoptOrphans();
    });
  }

  /// Дописывает сеткой вложения, которых нет в тексте записи.
  ///
  /// Записи из старых версий и из синка держат фотографии отдельно от текста —
  /// без этого редактор их не показывал, и человек видел голый текст там, где
  /// в читалке была галерея. Зовём только при открытии: у свежих вложений своё
  /// место есть, их ставит [_insertMedia] по курсору.
  void _adoptOrphans() => EditorDocument.adopt(
        _blocks,
        // Обложка из сети — шапка записи, а не вложение: её сюда не тянем.
        [
          for (final m in _media)
            if (m.id != _entry.coverMediaId) m.id,
        ],
        newBlock: _newTextBlock,
      );

  /// Ставит вложения туда, где стоит курсор: текстовый блок разрезается, а
  /// между половинами появляется сетка.
  void _insertMedia(List<Media> added) {
    if (added.isEmpty) return;
    final ids = added.map((m) => m.id).toList();
    final active = _active;
    final index = active == null ? -1 : _blocks.indexOf(active);

    setState(() {
      if (active == null || index < 0) {
        _blocks.add(MediaBlock(ids, createdAt: DateTime.now()));
        final tail = _newTextBlock();
        _blocks.add(tail);
        _active = tail;
        return;
      }

      final text = active.controller.text;
      final at = active.controller.selection.baseOffset.clamp(0, text.length);
      final before = text.substring(0, at);
      final after = text.substring(at);

      // Добавляем в соседнюю сетку, если курсор стоит в пустом абзаце рядом с
      // ней: иначе каждое следующее фото становилось отдельным блоком во всю
      // ширину, хотя при чтении они склеивались в одну сетку.
      final neighbour = _adjacentMediaBlock(index, before, after);
      if (neighbour != null) {
        neighbour.mediaIds.addAll(ids);
        return;
      }

      active.controller.text = before;
      final tail = _newTextBlock(after);
      _blocks
        ..insert(index + 1, MediaBlock(ids, createdAt: DateTime.now()))
        ..insert(index + 2, tail);
      _active = tail;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => tail.focus.requestFocus());
    });
    _dirty = true;
    _scheduleSave();
  }

  /// Сетка, к которой примыкает пустой абзац с курсором.
  ///
  /// Пустой абзац между двумя сетками — это не «текст между фотографиями», а
  /// след от предыдущей вставки: показывать его как разрыв неправильно.
  MediaBlock? _adjacentMediaBlock(int index, String before, String after) {
    if (before.trim().isNotEmpty || after.trim().isNotEmpty) return null;
    for (final at in [index - 1, index + 1]) {
      if (at < 0 || at >= _blocks.length) continue;
      final block = _blocks[at];
      if (block is MediaBlock) return block;
    }
    return null;
  }

  /// Убирает вложение из текста и из записи.
  Future<void> _removeMedia(Media m) async {
    Haptics.warn();
    setState(() {
      for (final block in _blocks.whereType<MediaBlock>()) {
        block.mediaIds.remove(m.id);
      }
      _blocks.removeWhere((b) => b is MediaBlock && b.mediaIds.isEmpty);
      if (_blocks.isEmpty) _blocks.add(_newTextBlock());
    });
    await MediaRepository.instance.delete(m);
    await _loadMedia();
    _dirty = true;
    _scheduleSave();
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

    final body = _bodyText;
    // Засчитываем только время с прошлого сохранения. Раньше прибавлялся весь
    // промежуток от открытия редактора, и при автосохранении каждые две
    // секунды счётчик разгонялся квадратично: за шесть секунд показывал
    // двенадцать.
    final now = DateTime.now();
    final sinceLastSave = now.difference(_countedAt).inMilliseconds;
    _countedAt = now;

    final entry = _entry.copyWith(
      title: _title.text.trim(),
      body: body,
      wordCount: MarkdownLite.wordCount(body),
      blockTimes: EditorDocument.timesOf(_blocks, fallback: _entry.entryDate),
      writeMs: _entry.writeMs + sinceLastSave,
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
      _title.text.trim().isEmpty && _bodyText.trim().isEmpty && _media.isEmpty;

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
    // Финал усилия: запись состоялась.
    Haptics.celebrate();
    _autosave?.cancel();
    await _save(finish: true);
    if (mounted) Navigator.of(context).pop(_entry);
  }

  // ------------------------------ Действия ------------------------------

  void _format(String marker, {bool prefix = false}) {
    final active = _active ?? _blocks.whereType<TextBlock>().firstOrNull;
    if (active == null) return;
    final controller = active.controller;
    final result = prefix
        ? MarkdownEdit.togglePrefix(
            controller.text, controller.selection, marker)
        : MarkdownEdit.toggleInline(
            controller.text, controller.selection, marker);
    controller.value = TextEditingValue(
      text: result.text,
      selection: result.selection,
    );
    active.focus.requestFocus();
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

  /// Смена времени появления темы — тап по времени в шапке блока. Как и у даты
  /// записи, спрашиваем и день, и время: тему можно поставить задним числом.
  Future<void> _editBlockTime(TextBlock block) async {
    final current = block.createdAt ?? _entry.entryDate;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted) return;
    setState(() {
      block.createdAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? current.hour,
        time?.minute ?? current.minute,
      );
      _dirty = true;
    });
    _scheduleSave();
  }

  /// Время темы в шапке блока: тап открывает смену.
  Widget _blockTime(TextBlock block, ColorScheme scheme) {
    final at = block.createdAt!;
    final label = Dates.sameDay(at, _entry.entryDate)
        ? Dates.time(at)
        : '${Dates.dayMonth(at)}, ${Dates.time(at)}';
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 1),
      child: InkWell(
        onTap: () => _editBlockTime(block),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            label,
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

  /// Выбор обложки: выключить, взять фото из записи или подобрать по теме.
  Future<void> _pickCover() async {
    await _save();
    if (!mounted) return;
    final hasPhoto = _media.any((m) => m.isVisual);
    final topic = [
      _title.text.trim(),
      ...MarkdownLite.hashtags(_bodyText),
    ].where((s) => s.isNotEmpty).join(' ');

    final choice = await showCoverSheet(
      context,
      entryId: _entry.id,
      current: _entry.coverMode,
      topic: topic,
      hasOwnPhoto: hasPhoto,
    );
    if (choice == null || !mounted) return;

    // Снимок обложки живёт, только пока он обложка. Сменили или выключили —
    // удаляем: иначе он остаётся вложением и всплывает в галерее записи как
    // фотография, которую человек туда не клал. Это верно и для скачанного по
    // теме, и для своего кадрированного.
    final stale = _entry.coverMode.isPinned ? _entry.coverMediaId : null;

    setState(() {
      _entry = _entry.copyWith(
        coverMode: choice.mode,
        coverMediaId: choice.mediaId,
        clearCover: !choice.mode.isPinned && choice.mediaId == null,
      );
      _dirty = true;
    });

    if (stale != null && stale != choice.mediaId) {
      final old = _media.where((m) => m.id == stale).firstOrNull;
      if (old != null) await MediaRepository.instance.delete(old);
    }
    await _loadMedia();
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
    if (added.isEmpty) return;
    await _loadMedia();
    _insertMedia(added);
  }

  Future<void> _takePhoto() async {
    await _save();
    final added =
        await MediaService.takePhoto(_entry.id, sort: _media.length);
    if (added == null) return;
    await _loadMedia();
    _insertMedia([added]);
  }

  Future<void> _addVideo() async {
    await _save();
    final added = await MediaService.pickVideo(_entry.id, sort: _media.length);
    if (added == null) return;
    await _loadMedia();
    _insertMedia([added]);
  }

  Future<void> _addSketch() async {
    await _save();
    if (!mounted) return;
    final png = await showSketchSheet(context);
    if (png == null) return;
    final added =
        await MediaService.attachSketch(_entry.id, png, sort: _media.length);
    await _loadMedia();
    _insertMedia([added]);
  }

  Future<void> _voice() async {
    await _save();
    if (!mounted) return;
    final result = await showVoiceSheet(context, entryId: _entry.id);
    if (result == null || !mounted) return;

    final active = _active ?? _blocks.whereType<TextBlock>().firstOrNull;
    if (result.transcript != null &&
        result.transcript!.isNotEmpty &&
        active != null) {
      final controller = active.controller;
      final insertion = controller.text.isEmpty
          ? result.transcript!
          : ' ${result.transcript!}';
      final edit = MarkdownEdit.insert(
          controller.text, controller.selection, insertion);
      controller.value =
          TextEditingValue(text: edit.text, selection: edit.selection);
    }
    if (result.audioPath != null) {
      final added = await MediaService.attachAudio(
        _entry.id,
        result.audioPath!,
        durationMs: result.durationMs,
        sort: _media.length,
      );
      await _loadMedia();
      _insertMedia([added]);
    }
  }

  // ------------------------------- Вид -------------------------------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final words = MarkdownLite.wordCount(_bodyText);

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
                    // Без этого TextField держит одну строку и длинный
                    // заголовок уезжает вбок: видно только его начало.
                    maxLines: null,
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
                  // Лента блоков: абзацы и сетки вложений между ними.
                  // Порядок меняется удержанием — список свой, но прокрутка
                  // общая с экраном, поэтому своей у него нет.
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _blocks.length,
                    onReorder: _reorderBlocks,
                    proxyDecorator: _draggedBlock,
                    itemBuilder: (context, i) =>
                        ReorderableDelayedDragStartListener(
                      // Ключ по самому блоку: у него живут контроллеры текста
                      // и фокус, и при перестановке они должны переехать
                      // вместе с блоком, а не остаться на месте.
                      key: ObjectKey(_blocks[i]),
                      index: i,
                      child: _buildBlock(context, _blocks[i], i),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _addBlock,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: const StadiumBorder(),
                        side: BorderSide(color: scheme.outlineVariant),
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(tr('block_add')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    // Показываем засчитанное плюс незасчитанный хвост текущего
                    // захода — ровно то, что уйдёт в базу на ближайшем
                    // сохранении.
                    '${Dates.wordCount(words)} · '
                    '${Dates.minutes(_entry.writeMs + DateTime.now().difference(_countedAt).inMilliseconds)}',
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

  Widget _buildBlock(BuildContext context, EditorBlock block, int index) {
    final scheme = Theme.of(context).colorScheme;

    switch (block) {
      case TextBlock():
        // Каждая тема — своя карточка: так запись читается как страница из
        // блоков, а не как сплошная стена текста на тёмном фоне.
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(WicklyDesign.radiusCard),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: block.title,
                        focusNode: block.titleFocus,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: -0.2,
                          color: scheme.onSurface,
                        ),
                        // Тема тоже переносится: у длинных заголовков было
                        // видно только начало. Ценой ухода Enter в перенос
                        // строки — прыжок в текст по Enter невозможен.
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: tr('block_title_hint'),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    // Когда появилась эта тема. У записи целиком время своё,
                    // но темы пишутся в разные заходы, и по ним видно, что
                    // утреннее, а что вечернее. Тап — сменить, в том числе на
                    // другой день (тогда рядом со временем встаёт и дата).
                    if (block.createdAt != null) _blockTime(block, scheme),
                    // Ручка переноса. Удержание на самой карточке тоже
                    // работает, но внутри текста длинный тап забирает
                    // выделение — иначе текст нельзя было бы выделить.
                    // Здесь захват мгновенный и не спорит ни с чем.
                    if (_blocks.length > 1)
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6, top: 2),
                          child: Icon(
                            Icons.drag_indicator_rounded,
                            size: 20,
                            color: scheme.outline,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: block.controller,
                  focusNode: block.focus,
                  maxLines: null,
                  minLines: index == 0 && _blocks.length == 1 ? 4 : 1,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15,
                    height: 1.5,
                    color: scheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: index == 0 ? tr('entry_body_hint') : null,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  onChanged: (value) => _continueList(block.controller, value),
                ),
                // Пустой лишний блок должен уметь исчезнуть.
                if (_blocks.length > 1 && block.isEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _removeBlock(block),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(tr('block_remove')),
                    ),
                  ),
              ],
            ),
          ),
        );

      case MediaBlock(:final mediaIds):
        final items = [
          for (final id in mediaIds)
            if (_mediaById[id] != null) _mediaById[id]!,
        ];
        if (items.isEmpty) return const SizedBox.shrink();
        // Голос показываем плеером, как в читалке. В сетке он превращался в
        // безликую плитку и прятался под «+N» среди фотографий — человек
        // считал, что заметка не записалась.
        final visual =
            items.where((m) => m.kind != MediaKind.audio).toList();
        final audio = items.where((m) => m.kind == MediaKind.audio).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visual.isNotEmpty)
                MediaGrid(
                  media: visual,
                  onOpen: (i) => showMediaViewer(context, visual, i),
                  onRemove: _removeMedia,
                ),
              for (final m in audio)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(child: AudioPlayerBar(media: m)),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: tr('delete'),
                        onPressed: () => _removeMedia(m),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
    }
  }

  /// Меняет блоки местами после перетаскивания.
  void _reorderBlocks(int oldIndex, int newIndex) {
    setState(() => EditorDocument.reorder(_blocks, oldIndex, newIndex));
    _dirty = true;
    _scheduleSave();
  }

  /// Как выглядит блок в руке. Тени в Wickly нет нигде, поэтому «поднимаем»
  /// его лёгким увеличением, а не подложкой с elevation, как делает M3.
  Widget _draggedBlock(Widget child, int index, Animation<double> animation) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1 + 0.03 * t,
            child: Opacity(opacity: 1 - 0.06 * t, child: child),
          );
        },
        child: child,
      );

  /// Добавляет новую тему в конец записи.
  void _addBlock() {
    final block = _newTextBlock();
    setState(() {
      _blocks.add(block);
      _active = block;
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => block.titleFocus.requestFocus());
    _dirty = true;
    _scheduleSave();
  }

  void _removeBlock(TextBlock block) {
    setState(() {
      _blocks.remove(block);
      if (_blocks.isEmpty) _blocks.add(_newTextBlock());
      _active = _blocks.whereType<TextBlock>().lastOrNull;
    });
    block.dispose();
    _dirty = true;
    _scheduleSave();
  }

  /// Enter внутри списка продолжает список.
  void _continueList(MarkdownEditingController controller, String value) {
    if (!value.endsWith('\n')) return;
    final before = value.substring(0, value.length - 1);
    final result = MarkdownEdit.continueList(
      before,
      TextSelection.collapsed(offset: before.length),
    );
    if (result == null) return;
    controller.value = TextEditingValue(
      text: result.text,
      selection: result.selection,
    );
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
          icon: switch (e.coverMode) {
            CoverMode.none => Icons.crop_din_rounded,
            CoverMode.auto => Icons.photo_rounded,
            CoverMode.web => Icons.image_search_rounded,
            CoverMode.own => Icons.crop_rounded,
          },
          label: tr('cover'),
          onTap: _pickCover,
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
            // Один ряд с прокруткой: два ряда съедали высоту у текста, а
            // разделитель показывает, где кончается разметка и начинаются
            // вложения.
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
              const _ToolDivider(),
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

/// Тонкая черта между разметкой и вложениями в панели.
class _ToolDivider extends StatelessWidget {
  const _ToolDivider();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        child: SizedBox(
          width: 1,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      );
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
              Haptics.tap();
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
