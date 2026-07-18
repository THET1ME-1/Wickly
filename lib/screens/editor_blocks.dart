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

/// Абзац текста со своим полем ввода.
class TextBlock extends EditorBlock {
  final MarkdownEditingController controller;
  final FocusNode focus;

  TextBlock({String text = ''})
      : controller = MarkdownEditingController(text: text),
        focus = FocusNode();

  void dispose() {
    controller.dispose();
    focus.dispose();
  }
}

/// Пачка вложений, вставленная в одно место.
class MediaBlock extends EditorBlock {
  final List<String> mediaIds;

  MediaBlock(this.mediaIds);
}

/// Перевод записи из текста в блоки и обратно.
class EditorDocument {
  const EditorDocument._();

  /// Разбирает текст записи на блоки.
  ///
  /// Идущие подряд вложения склеиваются в один блок: человек вставил их вместе,
  /// значит и сетка у них общая.
  static List<EditorBlock> parse(String? source) {
    final blocks = <EditorBlock>[];
    final lines = (source ?? '').split('\n');

    final buffer = <String>[];
    void flushText() {
      if (buffer.isEmpty) return;
      blocks.add(TextBlock(text: buffer.join('\n')));
      buffer.clear();
    }

    for (final line in lines) {
      final media = _mediaId(line);
      if (media == null) {
        buffer.add(line);
        continue;
      }
      flushText();
      final last = blocks.isEmpty ? null : blocks.last;
      if (last is MediaBlock) {
        last.mediaIds.add(media);
      } else {
        blocks.add(MediaBlock([media]));
      }
    }
    flushText();

    // Пустая запись — это всё-таки одно поле ввода, а не пустота.
    if (blocks.isEmpty) blocks.add(TextBlock());
    // После вложений в конце нужен текстовый блок, иначе писать дальше некуда.
    if (blocks.last is MediaBlock) blocks.add(TextBlock());
    return blocks;
  }

  /// Собирает блоки обратно в текст записи.
  static String serialize(List<EditorBlock> blocks) {
    final parts = <String>[];
    for (final block in blocks) {
      switch (block) {
        case TextBlock(:final controller):
          parts.add(controller.text);
        case MediaBlock(:final mediaIds):
          parts.addAll(mediaIds.map(MarkdownLite.mediaToken));
      }
    }
    return parts.join('\n').trim();
  }

  static String? _mediaId(String line) {
    final match =
        RegExp(r'^!\[\]\(media:([A-Za-z0-9-]+)\)$').firstMatch(line.trim());
    return match?.group(1);
  }
}
