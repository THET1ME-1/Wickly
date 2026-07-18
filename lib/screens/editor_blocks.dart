import 'package:flutter/material.dart';

import '../widgets/markdown_controller.dart';
import '../widgets/markdown_lite.dart';

/// Кусок записи в редакторе: либо текст, либо пачка вложений.
///
/// Редактор держит запись не одним полем, а лентой блоков — иначе фотографию
/// нельзя показать там, куда её поставил человек: внутри `TextField` картинка
/// не живёт. В базу всё равно уезжает обычный текст с разметкой, поэтому
/// поиск, экспорт и синхронизация ничего об этих блоках не знают.
sealed class EditorBlock {
  const EditorBlock();
}

/// Кусок записи со своим заголовком и текстом.
///
/// Заголовок необязателен: без него блок — обычный абзац. С ним запись
/// превращается в страницу из тем, где каждая мысль стоит отдельно и не
/// сливается с соседней в сплошную стену.
class TextBlock extends EditorBlock {
  final TextEditingController title;
  final MarkdownEditingController controller;
  final FocusNode titleFocus;
  final FocusNode focus;

  /// Когда тема появилась. Null — у старой записи времени нет, показывать
  /// нечего: выдумывать «сейчас» для текста трёхлетней давности нельзя.
  DateTime? createdAt;

  TextBlock({String text = '', String heading = '', this.createdAt})
      : title = TextEditingController(text: heading),
        controller = MarkdownEditingController(text: text),
        titleFocus = FocusNode(),
        focus = FocusNode();

  bool get isEmpty =>
      title.text.trim().isEmpty && controller.text.trim().isEmpty;

  void dispose() {
    title.dispose();
    controller.dispose();
    titleFocus.dispose();
    focus.dispose();
  }
}

/// Пачка вложений, вставленная в одно место.
class MediaBlock extends EditorBlock {
  final List<String> mediaIds;

  DateTime? createdAt;

  MediaBlock(this.mediaIds, {this.createdAt});
}

/// Перевод записи из текста в блоки и обратно.
class EditorDocument {
  const EditorDocument._();

  /// Раздаёт блокам их время из записи.
  ///
  /// Список времён хранится отдельно от текста и может с ним разойтись —
  /// после правок в другой версии или после синхронизации. Лишнее
  /// отбрасываем, недостающему времени ставим [fallback] — время записи.
  static void applyTimes(
    List<EditorBlock> blocks,
    List<int> times, {
    required DateTime fallback,
  }) {
    for (var i = 0; i < blocks.length; i++) {
      final at = i < times.length
          ? DateTime.fromMillisecondsSinceEpoch(times[i])
          : fallback;
      switch (blocks[i]) {
        case TextBlock b:
          b.createdAt = at;
        case MediaBlock b:
          b.createdAt = at;
      }
    }
  }

  /// Времена блоков в том же порядке — для сохранения в запись.
  static List<int> timesOf(List<EditorBlock> blocks, {DateTime? fallback}) => [
        for (final b in blocks)
          (switch (b) {
                    TextBlock() => b.createdAt,
                    MediaBlock() => b.createdAt,
                  } ??
                  fallback ??
                  DateTime.now())
              .millisecondsSinceEpoch,
      ];

  /// Переставляет блок с позиции [oldIndex] на [newIndex].
  ///
  /// Отдельно от экрана, потому что индексы у перетаскивания коварные:
  /// Flutter отдаёт позицию вставки ДО удаления элемента, и без поправки блок
  /// уезжает на одну позицию дальше при движении вниз.
  static void reorder(List<EditorBlock> blocks, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= blocks.length) return;
    var target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    target = target.clamp(0, blocks.length - 1);
    final block = blocks.removeAt(oldIndex);
    blocks.insert(target, block);
  }

  /// Разбирает текст записи на блоки.
  ///
  /// Идущие подряд вложения склеиваются в один блок: человек вставил их вместе,
  /// значит и сетка у них общая.
  static List<EditorBlock> parse(String? source) {
    final blocks = <EditorBlock>[];
    final lines = (source ?? '').split('\n');

    final buffer = <String>[];
    var heading = '';
    void flushText() {
      if (buffer.isEmpty && heading.isEmpty) return;
      blocks.add(TextBlock(text: buffer.join('\n').trim(), heading: heading));
      buffer.clear();
      heading = '';
    }

    for (final line in lines) {
      // Заголовок второго уровня начинает новый блок — так запись и хранится
      // обычным markdown, и раскладывается на темы.
      final head = _heading(line);
      if (head != null) {
        flushText();
        heading = head;
        continue;
      }

      final media = _mediaId(line);
      if (media == null) {
        buffer.add(line);
        continue;
      }
      // Пустые строки перед вложением — не абзац, а разделитель. Иначе между
      // двумя сетками появлялся пустой блок и рвал их на две.
      if (buffer.every((l) => l.trim().isEmpty)) buffer.clear();
      flushText();
      final last = blocks.isEmpty ? null : blocks.last;
      if (last is MediaBlock) {
        last.mediaIds.add(media);
      } else {
        blocks.add(MediaBlock([media]));
      }
    }
    if (buffer.every((l) => l.trim().isEmpty)) buffer.clear();
    flushText();

    // Пустая запись — это всё-таки одно поле ввода, а не пустота.
    if (blocks.isEmpty) blocks.add(TextBlock());
    // После вложений в конце нужен текстовый блок, иначе писать дальше некуда.
    if (blocks.last is MediaBlock) blocks.add(TextBlock());
    return blocks;
  }

  /// Дописывает сеткой вложения, которых нет в тексте.
  ///
  /// Записи из старых версий и из синка держат фотографии отдельно от текста:
  /// без этого редактор их не показывал, и человек видел голый текст там, где
  /// в читалке была галерея. Новый текстовый блок берём снаружи — редактор
  /// подписывается на каждый свой.
  static void adopt(
    List<EditorBlock> blocks,
    Iterable<String> mediaIds, {
    required TextBlock Function() newBlock,
  }) {
    final referenced = {
      for (final b in blocks.whereType<MediaBlock>()) ...b.mediaIds,
    };
    final orphans = [
      for (final id in mediaIds)
        if (!referenced.contains(id)) id,
    ];
    if (orphans.isEmpty) return;

    // Пустой хвостовой абзац остаётся последним: в него пишут дальше.
    final last = blocks.isEmpty ? null : blocks.last;
    final at =
        last is TextBlock && last.isEmpty ? blocks.length - 1 : blocks.length;
    blocks.insert(at, MediaBlock(orphans));
    if (at == blocks.length - 1) blocks.add(newBlock());
  }

  /// Собирает блоки обратно в текст записи.
  static String serialize(List<EditorBlock> blocks) {
    final parts = <String>[];
    for (final block in blocks) {
      switch (block) {
        case TextBlock(:final title, :final controller):
          final heading = title.text.trim();
          if (heading.isNotEmpty) parts.add('## $heading');
          if (controller.text.trim().isNotEmpty) parts.add(controller.text);
        case MediaBlock(:final mediaIds):
          parts.addAll(mediaIds.map(MarkdownLite.mediaToken));
      }
    }
    return parts.join('\n').trim();
  }

  /// «## Заголовок» → «Заголовок».
  static String? _heading(String line) =>
      RegExp(r'^##\s+(.*)$').firstMatch(line.trim())?.group(1)?.trim();

  static String? _mediaId(String line) {
    final match =
        RegExp(r'^!\[\]\(media:([A-Za-z0-9-]+)\)$').firstMatch(line.trim());
    return match?.group(1);
  }
}
