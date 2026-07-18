import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/editor_blocks.dart';
import 'package:wickly/widgets/markdown_lite.dart';

/// Блоки редактора — это только способ показать запись; в базу уезжает обычный
/// текст. Поэтому главное здесь — что текст переживает круг «разобрать → собрать».
void main() {
  test('Пустая запись — один текстовый блок', () {
    final blocks = EditorDocument.parse(null);
    expect(blocks.length, 1);
    expect(blocks.first, isA<TextBlock>());
    expect(EditorDocument.serialize(blocks), '');
  });

  test('Текст без вложений остаётся одним блоком', () {
    final blocks = EditorDocument.parse('Первая строка\nВторая строка');
    expect(blocks.whereType<TextBlock>().length, 1);
    expect(EditorDocument.serialize(blocks), 'Первая строка\nВторая строка');
  });

  test('Фото посреди текста разрезает его на два абзаца', () {
    final source = 'До фото\n${MarkdownLite.mediaToken('abc')}\nПосле фото';
    final blocks = EditorDocument.parse(source);
    expect(blocks.length, 3);
    expect(blocks[0], isA<TextBlock>());
    expect(blocks[1], isA<MediaBlock>());
    expect(blocks[2], isA<TextBlock>());
    expect(EditorDocument.serialize(blocks), source);
  });

  test('Идущие подряд фото склеиваются в одну сетку', () {
    final source = '${MarkdownLite.mediaToken('a')}\n'
        '${MarkdownLite.mediaToken('b')}\n'
        '${MarkdownLite.mediaToken('c')}';
    final blocks = EditorDocument.parse(source);
    final media = blocks.whereType<MediaBlock>().toList();
    expect(media.length, 1);
    expect(media.first.mediaIds, ['a', 'b', 'c']);
  });

  test('После вложений в конце есть куда писать дальше', () {
    final blocks = EditorDocument.parse(MarkdownLite.mediaToken('a'));
    expect(blocks.last, isA<TextBlock>());
  });

  test('Порядок фото и текста сохраняется полностью', () {
    final source = 'Раз\n'
        '${MarkdownLite.mediaToken('a')}\n'
        'Два\n'
        '${MarkdownLite.mediaToken('b')}\n'
        '${MarkdownLite.mediaToken('c')}\n'
        'Три';
    expect(EditorDocument.serialize(EditorDocument.parse(source)), source);
  });

  test('Вложения не попадают в текст превью и в счёт слов', () {
    final source = 'Вечер у реки\n${MarkdownLite.mediaToken('abc')}';
    expect(MarkdownLite.strip(source), 'Вечер у реки');
    expect(MarkdownLite.wordCount(source), 3);
  });

  test('Разметка блока вложения разбирается в отдельный вид', () {
    final blocks = MarkdownLite.parse(MarkdownLite.mediaToken('xyz'));
    expect(blocks.single.kind, MdBlockKind.media);
    expect(blocks.single.mediaId, 'xyz');
  });
}
