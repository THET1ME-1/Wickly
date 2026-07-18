import 'package:flutter/material.dart';

import '../models/media.dart';
import '../theme/app_theme.dart';
import 'audio_player_bar.dart';
import 'media_grid.dart';

/// Вид строки-блока в тексте записи.
enum MdBlockKind {
  paragraph,
  heading,
  quote,
  bullet,
  numbered,
  todo,
  divider,

  /// Вложение внутри текста: `![](media:ID)`.
  ///
  /// Фото живёт там, куда его поставил человек, а не отдельной полосой внизу.
  /// Идущие подряд вложения рендерятся одной сеткой.
  media,
}

/// Разобранная строка текста записи.
class MdBlock {
  final MdBlockKind kind;
  final String text;

  /// Уровень заголовка (1..3) или номер пункта.
  final int level;

  /// Отмечен ли пункт чеклиста.
  final bool checked;

  /// Номер исходной строки — по нему чеклист меняет текст на месте.
  final int line;

  /// Id вложения для [MdBlockKind.media].
  final String? mediaId;

  const MdBlock({
    required this.kind,
    required this.text,
    this.level = 0,
    this.checked = false,
    required this.line,
    this.mediaId,
  });
}

/// Лёгкая разметка записи: заголовки, жирный, курсив, списки, чеклисты,
/// цитаты, разделители и хэштеги.
///
/// Свой разбор, а не пакет: нужен ровно этот набор, полный CommonMark в дневнике
/// лишний, а рендер должен идти по ролям темы M3 и уметь **отмечать пункты
/// чеклиста прямо в читалке**, возвращая изменённый текст обратно в запись.
class MarkdownLite {
  const MarkdownLite._();

  static final _heading = RegExp(r'^(#{1,3})\s+(.*)$');
  static final _quote = RegExp(r'^>\s?(.*)$');
  static final _todo = RegExp(r'^[-*]\s+\[([ xX])\]\s+(.*)$');
  static final _bullet = RegExp(r'^[-*]\s+(.*)$');
  static final _numbered = RegExp(r'^(\d+)[.)]\s+(.*)$');
  static final _divider = RegExp(r'^(-{3,}|\*{3,})$');
  static final _media = RegExp(r'^!\[\]\(media:([A-Za-z0-9-]+)\)$');

  /// Как вложение записывается в текст. Формат нарочно похож на markdown:
  /// экспорт превращает его в обычную картинку, а не в мусор.
  static String mediaToken(String mediaId) => '![](media:$mediaId)';

  /// Разбирает текст на блоки построчно.
  static List<MdBlock> parse(String source) {
    final out = <MdBlock>[];
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final line = raw.trimRight();
      if (line.trim().isEmpty) continue;

      final media = _media.firstMatch(line.trim());
      if (media != null) {
        out.add(MdBlock(
          kind: MdBlockKind.media,
          text: '',
          line: i,
          mediaId: media.group(1),
        ));
        continue;
      }
      if (_divider.hasMatch(line.trim())) {
        out.add(MdBlock(kind: MdBlockKind.divider, text: '', line: i));
        continue;
      }
      final heading = _heading.firstMatch(line);
      if (heading != null) {
        out.add(MdBlock(
          kind: MdBlockKind.heading,
          text: heading.group(2)!,
          level: heading.group(1)!.length,
          line: i,
        ));
        continue;
      }
      final quote = _quote.firstMatch(line);
      if (quote != null) {
        out.add(MdBlock(
            kind: MdBlockKind.quote, text: quote.group(1)!, line: i));
        continue;
      }
      final todo = _todo.firstMatch(line);
      if (todo != null) {
        out.add(MdBlock(
          kind: MdBlockKind.todo,
          text: todo.group(2)!,
          checked: todo.group(1)!.toLowerCase() == 'x',
          line: i,
        ));
        continue;
      }
      final bullet = _bullet.firstMatch(line);
      if (bullet != null) {
        out.add(MdBlock(
            kind: MdBlockKind.bullet, text: bullet.group(1)!, line: i));
        continue;
      }
      final numbered = _numbered.firstMatch(line);
      if (numbered != null) {
        out.add(MdBlock(
          kind: MdBlockKind.numbered,
          text: numbered.group(2)!,
          level: int.tryParse(numbered.group(1)!) ?? 1,
          line: i,
        ));
        continue;
      }
      out.add(MdBlock(kind: MdBlockKind.paragraph, text: line, line: i));
    }
    return out;
  }

  /// Текст без разметки — для превью в ленте, поиска и счёта слов.
  static String strip(String? source) {
    if (source == null || source.isEmpty) return '';
    return parse(source)
        .where((b) =>
            b.kind != MdBlockKind.divider && b.kind != MdBlockKind.media)
        .map((b) => _stripInline(b.text))
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Сколько слов в записи.
  static int wordCount(String? source) {
    final plain = strip(source);
    if (plain.isEmpty) return 0;
    return plain.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Хэштеги из текста — они же становятся тегами записи.
  static List<String> hashtags(String? source) {
    if (source == null) return const [];
    return RegExp(r'(?<![\w#])#([\p{L}\p{N}_-]{2,30})', unicode: true)
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet()
        .toList();
  }

  /// Переключает пункт чеклиста в строке [line] и возвращает новый текст.
  static String toggleTodo(String source, int line) {
    final lines = source.split('\n');
    if (line < 0 || line >= lines.length) return source;
    final m = _todo.firstMatch(lines[line].trimRight());
    if (m == null) return source;
    final checked = m.group(1)!.toLowerCase() == 'x';
    lines[line] = '- [${checked ? ' ' : 'x'}] ${m.group(2)}';
    return lines.join('\n');
  }

  static String _stripInline(String s) => s
      .replaceAll(RegExp(r'\*\*|__'), '')
      .replaceAll(RegExp(r'(?<!\w)[*_](?!\s)'), '')
      .replaceAll('`', '');
}

/// Рендер размеченного текста записи.
class MarkdownBody extends StatelessWidget {
  final String source;

  /// Нажатие на пункт чеклиста. Отдаёт уже изменённый текст целиком.
  final ValueChanged<String>? onToggleTodo;

  /// Размер основного текста — читалка уважает выбранный масштаб.
  final double fontSize;

  /// Вложения записи по их id — то, на что ссылается текст.
  final Map<String, Media> media;

  /// Открыть просмотр вложения.
  final void Function(List<Media> group, int index)? onOpenMedia;

  const MarkdownBody({
    super.key,
    required this.source,
    this.onToggleTodo,
    this.fontSize = 15,
    this.media = const {},
    this.onOpenMedia,
    this.cards = false,
  });

  /// Показывать ли темы карточками. В читалке — да: запись из нескольких тем
  /// иначе сливается в стену текста.
  final bool cards;

  @override
  Widget build(BuildContext context) {
    final blocks = MarkdownLite.parse(source);
    final children = <Widget>[];
    // Накопитель текущей темы: собирается до следующего заголовка второго
    // уровня или до вложений.
    var section = <Widget>[];
    String? sectionTitle;

    void flushSection() {
      if (section.isEmpty && sectionTitle == null) return;
      children.add(_section(context, sectionTitle, section));
      section = [];
      sectionTitle = null;
    }

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];

      if (cards && b.kind == MdBlockKind.heading && b.level == 2) {
        flushSection();
        sectionTitle = b.text;
        continue;
      }

      // Идущие подряд вложения собираем в одну сетку: человек вставил их в
      // одно место, значит и смотреть их надо вместе.
      if (b.kind == MdBlockKind.media) {
        final group = <Media>[];
        while (i < blocks.length && blocks[i].kind == MdBlockKind.media) {
          final m = media[blocks[i].mediaId];
          if (m != null) group.add(m);
          i++;
        }
        i--;
        if (group.isEmpty) continue;
        // Фотографии показываем во всю ширину, а не внутри карточки темы:
        // рамка вокруг снимка только мешает смотреть.
        flushSection();
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _mediaGroup(context, group),
        ));
        continue;
      }

      final widget = Padding(
        padding:
            EdgeInsets.only(bottom: b.kind == MdBlockKind.divider ? 14 : 8),
        child: _block(context, b),
      );
      if (cards) {
        section.add(widget);
      } else {
        children.add(widget);
      }
    }
    flushSection();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Одна тема: заголовок и текст в скруглённой карточке.
  Widget _section(BuildContext context, String? title, List<Widget> body) {
    final scheme = Theme.of(context).colorScheme;
    if (title == null && body.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w600,
                fontSize: fontSize + 2,
                letterSpacing: -0.2,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
          ],
          ...body,
        ],
      ),
    );
  }

  /// Голос показывается плеером, а не плиткой: у него нечего разглядывать.
  Widget _mediaGroup(BuildContext context, List<Media> group) {
    final audio = group.where((m) => m.kind == MediaKind.audio).toList();
    final visual = group.where((m) => m.kind != MediaKind.audio).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visual.isNotEmpty)
          MediaGrid(
            media: visual,
            onOpen: (index) => onOpenMedia?.call(visual, index),
          ),
        for (final a in audio)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AudioPlayerBar(media: a),
          ),
      ],
    );
  }

  Widget _block(BuildContext context, MdBlock b) {
    final scheme = Theme.of(context).colorScheme;
    switch (b.kind) {
      // Вложения собираются группами в build — сюда они не доходят.
      case MdBlockKind.media:
        return const SizedBox.shrink();

      case MdBlockKind.divider:
        return Divider(color: scheme.outlineVariant);

      case MdBlockKind.heading:
        return Text.rich(
          _inline(context, b.text,
              base: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: switch (b.level) {
                  1 => fontSize + 7,
                  2 => fontSize + 4,
                  _ => fontSize + 2,
                },
                letterSpacing: -0.3,
                color: scheme.onSurface,
              )),
        );

      case MdBlockKind.quote:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: scheme.primary, width: 3),
            ),
          ),
          child: Text.rich(
            _inline(context, b.text,
                base: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: fontSize,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: scheme.onSurfaceVariant,
                )),
          ),
        );

      case MdBlockKind.todo:
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onToggleTodo == null
              ? null
              : () => onToggleTodo!(MarkdownLite.toggleTodo(source, b.line)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  b.checked
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 21,
                  color: b.checked ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text.rich(
                    _inline(context, b.text,
                        base: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: fontSize,
                          height: 1.4,
                          color: b.checked
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          decoration:
                              b.checked ? TextDecoration.lineThrough : null,
                        )),
                  ),
                ),
              ],
            ),
          ),
        );

      case MdBlockKind.bullet:
      case MdBlockKind.numbered:
        final marker = b.kind == MdBlockKind.bullet ? '•' : '${b.level}.';
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Text(
                marker,
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: fontSize,
                  height: 1.5,
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                _inline(context, b.text, base: _bodyStyle(context)),
              ),
            ),
          ],
        );

      case MdBlockKind.paragraph:
        return Text.rich(_inline(context, b.text, base: _bodyStyle(context)));
    }
  }

  TextStyle _bodyStyle(BuildContext context) => TextStyle(
        fontFamily: AppTheme.bodyFont,
        fontSize: fontSize,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface,
      );

  /// Разбирает `**жирный**`, `*курсив*`, `` `код` `` и `#теги` внутри строки.
  static TextSpan _inline(
    BuildContext context,
    String text, {
    required TextStyle base,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final spans = <TextSpan>[];
    final pattern = RegExp(
      r'(\*\*[^*]+\*\*)|(__[^_]+__)|(\*[^*\n]+\*)|(`[^`]+`)'
      r'|((?<![\w#])#[\p{L}\p{N}_-]{2,30})',
      unicode: true,
    );

    var index = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > index) {
        spans.add(TextSpan(text: text.substring(index, m.start), style: base));
      }
      final token = m.group(0)!;
      if (token.startsWith('**') || token.startsWith('__')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(
            backgroundColor: scheme.surfaceContainerHighest,
            fontFamily: 'monospace',
          ),
        ));
      } else if (token.startsWith('#')) {
        spans.add(TextSpan(
          text: token,
          style: base.copyWith(
              color: scheme.primary, fontWeight: FontWeight.w600),
        ));
      } else {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      index = m.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index), style: base));
    }
    return TextSpan(children: spans, style: base);
  }
}
