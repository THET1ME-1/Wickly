import 'package:flutter/material.dart';

import '../models/media.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
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

  /// Размер заголовка по его уровню — один на всё приложение: поле ввода,
  /// читалка и заголовок темы должны показывать `#`/`##`/`###` одинаково.
  /// Заголовок должен явно читаться крупнее тела, иначе `## ` (его ставит
  /// кнопка и им же хранится тема) отличается от текста лишь на пару пунктов и
  /// выглядит «тем же размером».
  static double headingSize(int level, double base) => switch (level) {
        1 => base + 8,
        2 => base + 5,
        _ => base + 2,
      };

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
      // Ссылка на другую запись читается своим названием, скобки в выжимке
      // ни к чему.
      .replaceAllMapped(RegExp(r'\[\[([^\[\]\n]{1,120})\]\]'),
          (m) => m.group(1)!)
      .replaceAll(RegExp(r'\*\*|__'), '')
      .replaceAll(RegExp(r'(?<!\w)[*_](?!\s)'), '')
      .replaceAll('`', '');

  /// Нарезает запись на темы для читалки: карточка с заголовком и текстом либо
  /// сетка вложений.
  ///
  /// Граница темы — заголовок второго уровня (`## `) или пачка вложений, ровно
  /// как режет запись редактор ([EditorDocument.parse]). Поэтому порядковый
  /// номер темы совпадает с индексом её времени в `Entry.blockTimes`, и время,
  /// показанное при чтении, не разъезжается с тем, что задано в редакторе
  /// (тексты в базу приходят уже собранными и обрезанными, без ведущих пустых
  /// строк, — а только они могли бы сдвинуть нумерацию). Строки `MdBlock`
  /// хранят исходный номер, поэтому чеклист внутри темы правится по всему тексту.
  static List<ReadUnit> readUnits(String source) {
    final blocks = parse(source);
    final units = <ReadUnit>[];
    var body = <MdBlock>[];
    String? title;

    void flush() {
      if (body.isEmpty && title == null) return;
      units.add(ReadUnit(title: title, blocks: body));
      body = [];
      title = null;
    }

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      if (b.kind == MdBlockKind.heading && b.level == 2) {
        flush();
        title = b.text;
        continue;
      }
      if (b.kind == MdBlockKind.media) {
        final ids = <String>[];
        while (i < blocks.length && blocks[i].kind == MdBlockKind.media) {
          final id = blocks[i].mediaId;
          if (id != null) ids.add(id);
          i++;
        }
        i--;
        flush();
        units.add(ReadUnit(mediaIds: ids));
        continue;
      }
      body.add(b);
    }
    flush();
    return units;
  }
}

/// Одна тема записи для читалки — карточка текста или сетка вложений.
///
/// Держит уже разобранные строки ([blocks]) с их исходными номерами, чтобы
/// чеклист правился по всему тексту записи, а не по обрезку темы.
class ReadUnit {
  /// Заголовок темы. `null` — тема без заголовка (обычный абзац).
  final String? title;

  /// Строки текста темы. Пусто у сетки вложений.
  final List<MdBlock> blocks;

  /// Id вложений сетки. Непусто → это [isMedia].
  final List<String> mediaIds;

  const ReadUnit({
    this.title,
    this.blocks = const [],
    this.mediaIds = const [],
  });

  bool get isMedia => mediaIds.isNotEmpty;
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

  /// Времена тем (unix ms) в порядке нарезки [MarkdownLite.readUnits] — подпись
  /// под заголовком темы. Работает только с [cards].
  final List<int> blockTimes;

  /// Время записи. Им подписываются темы без своего времени, и по нему видно,
  /// что тема из другого дня (тогда показывается и дата). `null` — времена не
  /// показываем вовсе.
  final DateTime? entryDate;

  /// Сменить время темы по тапу: индекс темы в [blockTimes].
  final ValueChanged<int>? onEditTime;

  /// Нажатие на ссылку `[[Другая запись]]`. Без обработчика ссылка рисуется,
  /// но никуда не ведёт — так она выглядит в предпросмотре.
  final void Function(String target)? onLink;

  const MarkdownBody({
    super.key,
    required this.source,
    this.onToggleTodo,
    this.fontSize = 15,
    this.media = const {},
    this.onOpenMedia,
    this.cards = false,
    this.blockTimes = const [],
    this.entryDate,
    this.onEditTime,
    this.onLink,
  });

  /// Показывать ли темы карточками. В читалке — да: запись из нескольких тем
  /// иначе сливается в стену текста.
  final bool cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cards ? _cardChildren(context) : _flatChildren(context),
    );
  }

  /// Текст без карточек: блоки подряд, как в превью и в старых местах.
  List<Widget> _flatChildren(BuildContext context) {
    final blocks = MarkdownLite.parse(source);
    final children = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
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
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _mediaGroup(context, group),
        ));
        continue;
      }
      children.add(Padding(
        padding:
            EdgeInsets.only(bottom: b.kind == MdBlockKind.divider ? 14 : 8),
        child: _block(context, b),
      ));
    }
    return children;
  }

  /// Читалка: каждая тема — своя карточка со своим временем.
  List<Widget> _cardChildren(BuildContext context) {
    final units = MarkdownLite.readUnits(source);
    final children = <Widget>[];
    for (var index = 0; index < units.length; index++) {
      final u = units[index];
      if (u.isMedia) {
        // Фотографии показываем во всю ширину, а не внутри карточки темы:
        // рамка вокруг снимка только мешает смотреть.
        final group = <Media>[];
        for (final id in u.mediaIds) {
          final m = media[id];
          if (m != null) group.add(m);
        }
        if (group.isEmpty) continue;
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _mediaGroup(context, group),
        ));
        continue;
      }
      if (u.title == null && u.blocks.isEmpty) continue;
      final body = [
        for (final b in u.blocks)
          Padding(
            padding:
                EdgeInsets.only(bottom: b.kind == MdBlockKind.divider ? 14 : 8),
            child: _block(context, b),
          ),
      ];
      children.add(_section(context, u.title, body, index: index));
    }
    return children;
  }

  /// Одна тема: заголовок, время и текст в скруглённой карточке.
  Widget _section(
    BuildContext context,
    String? title,
    List<Widget> body, {
    required int index,
  }) {
    final scheme = Theme.of(context).colorScheme;
    if (title == null && body.isEmpty) return const SizedBox.shrink();

    final hasTitle = title != null && title.isNotEmpty;
    // Тема без своего времени берёт время записи — так же, как редактор
    // подставляет ему `fallback`.
    final at = entryDate == null
        ? null
        : (index < blockTimes.length
            ? DateTime.fromMillisecondsSinceEpoch(blockTimes[index])
            : entryDate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle || at != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTitle)
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        // Заголовок темы — это `## `, поэтому и размер как у
                        // заголовка второго уровня: тема должна читаться крупнее
                        // текста, а не сливаться с ним.
                        fontWeight: FontWeight.w700,
                        fontSize: MarkdownLite.headingSize(2, fontSize),
                        letterSpacing: -0.3,
                        color: scheme.onSurface,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (at != null) _time(context, at, index),
              ],
            ),
            const SizedBox(height: 8),
          ],
          ...body,
        ],
      ),
    );
  }

  /// Время появления темы. Тап открывает смену — в том числе на другой день,
  /// который тогда и показывается рядом со временем.
  Widget _time(BuildContext context, DateTime at, int index) {
    final scheme = Theme.of(context).colorScheme;
    final label = Dates.sameDay(at, entryDate!)
        ? Dates.time(at)
        : '${Dates.dayMonth(at)}, ${Dates.time(at)}';
    final text = Text(
      label,
      style: TextStyle(
        fontFamily: AppTheme.bodyFont,
        fontSize: 11.5,
        color: scheme.onSurfaceVariant,
      ),
    );
    if (onEditTime == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 8, top: 1),
        child: text,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => onEditTime!(index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: text,
        ),
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
                        onLink: onLink,
              base: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: MarkdownLite.headingSize(b.level, fontSize),
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
                        onLink: onLink,
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
                // Галочка не прыгает, а проявляется: отметить пункт — самое
                // приятное движение в чеклисте, и оно должно ощущаться.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: AppTheme.emphasized,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Icon(
                    b.checked
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    key: ValueKey(b.checked),
                    size: 21,
                    color: b.checked ? scheme.primary : scheme.outline,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text.rich(
                    _inline(context, b.text,
                        onLink: onLink,
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
                _inline(context, b.text, base: _bodyStyle(context), onLink: onLink),
              ),
            ),
          ],
        );

      case MdBlockKind.paragraph:
        return Text.rich(_inline(context, b.text, base: _bodyStyle(context), onLink: onLink));
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
    void Function(String target)? onLink,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    final pattern = RegExp(
      r'(\[\[[^\[\]\n]{1,120}\]\])'
      r'|(\*\*[^*]+\*\*)|(__[^_]+__)|(\*[^*\n]+\*)|(`[^`]+`)'
      r'|((?<![\w#])#[\p{L}\p{N}_-]{2,30})',
      unicode: true,
    );

    var index = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > index) {
        spans.add(TextSpan(text: text.substring(index, m.start), style: base));
      }
      final token = m.group(0)!;
      if (token.startsWith('[[')) {
        // Ссылка на другую запись. Виджетом, а не распознавателем жестов:
        // распознаватель в StatelessWidget некому освободить, а виджет ещё и
        // подсвечивается под курсором.
        final target = token.substring(2, token.length - 2).trim();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: WikiLinkSpan(
            target: target,
            style: base,
            onTap: onLink == null ? null : () => onLink(target),
          ),
        ));
      } else if (token.startsWith('**') || token.startsWith('__')) {
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

/// Ссылка на другую запись внутри текста.
///
/// Виджетом, а не распознавателем жестов в `TextSpan`: распознаватель надо
/// освобождать, а тут его некому — рендер живёт в `StatelessWidget`. Заодно
/// ссылка подсвечивается под курсором, чего от текста на десктопе и ждут.
class WikiLinkSpan extends StatefulWidget {
  final String target;
  final TextStyle style;
  final VoidCallback? onTap;

  const WikiLinkSpan({
    super.key,
    required this.target,
    required this.style,
    this.onTap,
  });

  @override
  State<WikiLinkSpan> createState() => _WikiLinkSpanState();
}

class _WikiLinkSpanState extends State<WikiLinkSpan> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: _hover
                ? scheme.secondaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          // Название записи показываем целиком: обрезанное многоточием, оно
          // перестаёт быть узнаваемым, а по нему ссылку и находят. Ширину
          // ограничивает сам абзац — внутри пилюли длинное имя переносится.
          child: Text(
            widget.target,
            style: widget.style.copyWith(
              color: _hover ? scheme.onSecondaryContainer : scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
