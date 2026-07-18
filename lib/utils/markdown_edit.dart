import 'package:flutter/services.dart';

/// Результат правки текста кнопкой панели форматирования.
class EditResult {
  final String text;
  final TextSelection selection;

  const EditResult(this.text, this.selection);
}

/// Что делают кнопки панели форматирования.
///
/// Чистые функции над текстом и выделением: панель их только вызывает, поэтому
/// поведение проверяется тестами, а не руками на телефоне.
class MarkdownEdit {
  const MarkdownEdit._();

  /// Оборачивает выделение парными символами (`**`, `*`, `` ` ``) или снимает
  /// обёртку, если она уже стоит. Без выделения ставит пустую пару и кладёт
  /// курсор внутрь — можно сразу печатать.
  static EditResult toggleInline(
    String text,
    TextSelection selection,
    String marker,
  ) {
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    final len = marker.length;

    if (start == end) {
      final inserted = text.replaceRange(start, start, '$marker$marker');
      return EditResult(
        inserted,
        TextSelection.collapsed(offset: start + len),
      );
    }

    final selected = text.substring(start, end);

    // Обёртка внутри выделения: «**жирный**» → «жирный».
    if (selected.length >= len * 2 &&
        selected.startsWith(marker) &&
        selected.endsWith(marker)) {
      final stripped = selected.substring(len, selected.length - len);
      final out = text.replaceRange(start, end, stripped);
      return EditResult(
        out,
        TextSelection(baseOffset: start, extentOffset: start + stripped.length),
      );
    }

    // Обёртка вокруг выделения: «**|жирный|**» → «жирный».
    if (start >= len &&
        end + len <= text.length &&
        text.substring(start - len, start) == marker &&
        text.substring(end, end + len) == marker) {
      final out = text.replaceRange(end, end + len, '')
          .replaceRange(start - len, start, '');
      return EditResult(
        out,
        TextSelection(
          baseOffset: start - len,
          extentOffset: end - len,
        ),
      );
    }

    final out = text.replaceRange(start, end, '$marker$selected$marker');
    return EditResult(
      out,
      TextSelection(
        baseOffset: start + len,
        extentOffset: end + len,
      ),
    );
  }

  /// Ставит или снимает приставку строки: `# `, `- `, `- [ ] `, `> `.
  ///
  /// Работает по всем строкам, которых касается выделение: выделил три строки —
  /// получил список из трёх пунктов.
  static EditResult togglePrefix(
    String text,
    TextSelection selection,
    String prefix,
  ) {
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);

    final lineStart = _lineStart(text, start);
    final lineEnd = _lineEnd(text, end);
    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');

    // Снимаем, только если приставка стоит у всех строк — иначе выравниваем.
    final allPrefixed = lines.every((l) => _hasPrefix(l, prefix));
    final changed = [
      for (final line in lines)
        allPrefixed ? _removePrefix(line, prefix) : _addPrefix(line, prefix),
    ];

    final replacement = changed.join('\n');
    final out = text.replaceRange(lineStart, lineEnd, replacement);
    final delta = replacement.length - block.length;
    return EditResult(
      out,
      TextSelection(
        baseOffset: lineStart,
        extentOffset: (end + delta).clamp(lineStart, out.length),
      ),
    );
  }

  /// Вставляет текст на место курсора (расшифровка речи, тег).
  static EditResult insert(
    String text,
    TextSelection selection,
    String insertion,
  ) {
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    final out = text.replaceRange(start, end, insertion);
    return EditResult(
      out,
      TextSelection.collapsed(offset: start + insertion.length),
    );
  }

  /// Продолжает список на новой строке: нажал Enter в пункте — получил
  /// следующий пункт. Пустой пункт вместо этого прерывает список.
  static EditResult? continueList(String text, TextSelection selection) {
    if (!selection.isCollapsed) return null;
    final offset = selection.start.clamp(0, text.length);
    final lineStart = _lineStart(text, offset);
    final line = text.substring(lineStart, offset);

    for (final prefix in const ['- [ ] ', '- [x] ', '- ', '> ']) {
      if (!line.startsWith(prefix)) continue;
      final marker = prefix == '- [x] ' ? '- [ ] ' : prefix;
      if (line.trimRight() == prefix.trimRight()) {
        // Пустой пункт — выходим из списка.
        final out = text.replaceRange(lineStart, offset, '');
        return EditResult(
          out,
          TextSelection.collapsed(offset: lineStart),
        );
      }
      final out = text.replaceRange(offset, offset, '\n$marker');
      return EditResult(
        out,
        TextSelection.collapsed(offset: offset + marker.length + 1),
      );
    }

    // Нумерованный список: «3. » → «4. ».
    final numbered = RegExp(r'^(\d+)([.)])\s').firstMatch(line);
    if (numbered != null) {
      final n = int.parse(numbered.group(1)!);
      if (line.trim() == '$n${numbered.group(2)}') {
        final out = text.replaceRange(lineStart, offset, '');
        return EditResult(out, TextSelection.collapsed(offset: lineStart));
      }
      final marker = '${n + 1}${numbered.group(2)} ';
      final out = text.replaceRange(offset, offset, '\n$marker');
      return EditResult(
        out,
        TextSelection.collapsed(offset: offset + marker.length + 1),
      );
    }

    return null;
  }

  static bool _hasPrefix(String line, String prefix) {
    if (prefix == '- [ ] ') {
      return line.startsWith('- [ ] ') || line.startsWith('- [x] ');
    }
    return line.startsWith(prefix);
  }

  static String _addPrefix(String line, String prefix) {
    // Заголовок поверх списка (и наоборот) заменяет старую приставку.
    final clean = _stripAnyPrefix(line);
    return '$prefix$clean';
  }

  static String _removePrefix(String line, String prefix) =>
      _stripAnyPrefix(line);

  static String _stripAnyPrefix(String line) {
    for (final p in const ['- [ ] ', '- [x] ', '### ', '## ', '# ', '- ', '> ']) {
      if (line.startsWith(p)) return line.substring(p.length);
    }
    final numbered = RegExp(r'^\d+[.)]\s').firstMatch(line);
    if (numbered != null) return line.substring(numbered.end);
    return line;
  }

  static int _lineStart(String text, int offset) {
    final i = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    return i < 0 ? 0 : i + 1;
  }

  static int _lineEnd(String text, int offset) {
    final i = text.indexOf('\n', offset);
    return i < 0 ? text.length : i;
  }
}
