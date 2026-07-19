import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'markdown_lite.dart';

/// Поле ввода, которое подсвечивает разметку прямо во время набора.
///
/// Полноценный WYSIWYG дневнику не нужен и стоит дорого: вместо него текст
/// остаётся обычным текстом, но жирное выглядит жирным, заголовок — крупным,
/// цитата — приглушённой, а сами символы разметки (`**`, `#`, `- [ ]`) гаснут
/// до полупрозрачных. Человек видит оформление и при этом может стереть любой
/// символ руками.
class MarkdownEditingController extends TextEditingController {
  MarkdownEditingController({super.text});

  static final _heading = RegExp(r'^(#{1,3})\s+', multiLine: true);
  static final _todo = RegExp(r'^([-*]\s+\[[ xX]\]\s+)', multiLine: true);
  static final _bullet = RegExp(r'^([-*]\s+)', multiLine: true);
  static final _quote = RegExp(r'^(>\s?)', multiLine: true);
  static final _inline = RegExp(
    r'(\*\*[^*\n]+\*\*)|(\*[^*\n]+\*)|(`[^`\n]+`)'
    r'|((?<![\w#])#[\p{L}\p{N}_-]{2,30})',
    unicode: true,
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final base = style ?? const TextStyle();
    final marker = base.copyWith(
      color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
      fontWeight: FontWeight.w400,
    );

    // Собираем разметку в карту «отрезок → стиль», затем режем текст по ней.
    final spans = <_Styled>[];

    void addLinePrefix(RegExp re, TextStyle Function(String body) bodyStyle) {
      for (final m in re.allMatches(text)) {
        final lineEnd = text.indexOf('\n', m.end);
        final end = lineEnd < 0 ? text.length : lineEnd;
        spans.add(_Styled(m.start, m.end, marker));
        spans.add(_Styled(m.end, end, bodyStyle(text.substring(m.end, end))));
      }
    }

    // Заголовок в поле показываем по уровню, той же лесенкой, что и читалка:
    // `## ` в наборе должен быть заметно крупнее текста, а не на пару пунктов.
    for (final m in _heading.allMatches(text)) {
      final level = m.group(1)!.length;
      final lineEnd = text.indexOf('\n', m.end);
      final end = lineEnd < 0 ? text.length : lineEnd;
      spans.add(_Styled(m.start, m.end, marker));
      spans.add(_Styled(
        m.end,
        end,
        base.copyWith(
          fontFamily: AppTheme.displayFont,
          fontWeight: FontWeight.w700,
          fontSize: MarkdownLite.headingSize(level, base.fontSize ?? 15),
        ),
      ));
    }
    addLinePrefix(_todo, (_) => base);
    addLinePrefix(_bullet, (_) => base);
    addLinePrefix(
      _quote,
      (_) => base.copyWith(
        fontStyle: FontStyle.italic,
        color: scheme.onSurfaceVariant,
      ),
    );

    for (final m in _inline.allMatches(text)) {
      final token = m.group(0)!;
      if (token.startsWith('#')) {
        spans.add(_Styled(
          m.start,
          m.end,
          base.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
        ));
        continue;
      }
      final len = token.startsWith('**') ? 2 : 1;
      final inner = token.startsWith('**')
          ? base.copyWith(fontWeight: FontWeight.w700)
          : token.startsWith('`')
              ? base.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: scheme.surfaceContainerHighest,
                )
              : base.copyWith(fontStyle: FontStyle.italic);
      spans
        ..add(_Styled(m.start, m.start + len, marker))
        ..add(_Styled(m.start + len, m.end - len, inner))
        ..add(_Styled(m.end - len, m.end, marker));
    }

    if (spans.isEmpty) return TextSpan(text: text, style: base);

    // Позднее правило побеждает: жирный внутри заголовка остаётся жирным.
    final styleAt = List<TextStyle>.filled(text.length, base);
    for (final s in spans) {
      for (var i = s.start; i < s.end && i < text.length; i++) {
        styleAt[i] = i < s.start + 0 ? styleAt[i] : _merge(styleAt[i], s.style);
      }
    }

    final out = <TextSpan>[];
    var runStart = 0;
    for (var i = 1; i <= text.length; i++) {
      if (i == text.length || styleAt[i] != styleAt[runStart]) {
        out.add(TextSpan(
          text: text.substring(runStart, i),
          style: styleAt[runStart],
        ));
        runStart = i;
      }
    }
    return TextSpan(children: out, style: base);
  }

  /// Склеивает стили так, чтобы приставка строки не съедала жирность внутри.
  static TextStyle _merge(TextStyle current, TextStyle next) =>
      current.merge(next);
}

class _Styled {
  final int start;
  final int end;
  final TextStyle style;
  const _Styled(this.start, this.end, this.style);
}
