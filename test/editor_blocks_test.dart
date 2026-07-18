import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/screens/editor_blocks.dart';
import 'package:wickly/widgets/markdown_lite.dart';

/// Блоки редактора — это только способ показать запись; в базу уезжает обычный
/// текст. Поэтому главное здесь — что текст переживает круг «разобрать → собрать».
void main() {
  _reorderTests();
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

  test('Пустой абзац между фото не разрывает сетку', () {
    // Так выглядит текст после двух вставок подряд: между вложениями остаётся
    // пустая строка. Сетка при этом должна остаться одна.
    final source = '${MarkdownLite.mediaToken('a')}\n\n'
        '${MarkdownLite.mediaToken('b')}';
    final blocks = EditorDocument.parse(source);
    final media = blocks.whereType<MediaBlock>().toList();
    expect(media.length, 1);
    expect(media.first.mediaIds, ['a', 'b']);
  });

  test('Настоящий текст между фото сетку разделяет', () {
    final source = '${MarkdownLite.mediaToken('a')}\n'
        'Между ними\n'
        '${MarkdownLite.mediaToken('b')}';
    final blocks = EditorDocument.parse(source);
    expect(blocks.whereType<MediaBlock>().length, 2);
  });

  test('Заголовок блока начинает новую тему', () {
    final blocks = EditorDocument.parse(
        '## Продуктивный сегодня\nВыписал теорию.\n## Вечер\nИграл с Саней.');
    final text = blocks.whereType<TextBlock>().toList();
    expect(text.length, 2);
    expect(text[0].title.text, 'Продуктивный сегодня');
    expect(text[0].controller.text, 'Выписал теорию.');
    expect(text[1].title.text, 'Вечер');
  });

  test('Темы переживают круг разбора и сборки', () {
    const source = '## Утро\nКофе и планы.\n## Вечер\nДошли до моста.';
    expect(EditorDocument.serialize(EditorDocument.parse(source)), source);
  });

  test('Блок без заголовка остаётся обычным абзацем', () {
    const source = 'Просто текст без темы.';
    final blocks = EditorDocument.parse(source);
    expect(blocks.whereType<TextBlock>().single.title.text, '');
    expect(EditorDocument.serialize(blocks), source);
  });

  test('Тема без текста не теряется', () {
    const source = '## Только заголовок';
    expect(EditorDocument.serialize(EditorDocument.parse(source)), source);
  });

  test('Фото старой записи всплывают в редакторе', () {
    // Записи до «фото внутри текста» держат вложения отдельно: в тексте про
    // них ни слова. Редактор обязан их показать, а не потерять.
    final blocks = EditorDocument.parse('Ходили на речку.');
    EditorDocument.adopt(blocks, ['a', 'b'], newBlock: TextBlock.new);

    final media = blocks.whereType<MediaBlock>().single;
    expect(media.mediaIds, ['a', 'b']);
    expect(EditorDocument.serialize(blocks),
        'Ходили на речку.\n${MarkdownLite.mediaToken('a')}\n'
        '${MarkdownLite.mediaToken('b')}');
  });

  test('Вложение из текста второй раз не подбирается', () {
    final blocks = EditorDocument.parse(
        'Смотри.\n${MarkdownLite.mediaToken('a')}');
    EditorDocument.adopt(blocks, ['a', 'b'], newBlock: TextBlock.new);

    final ids = blocks.whereType<MediaBlock>().expand((b) => b.mediaIds);
    expect(ids.toList(), ['a', 'b']);
  });

  test('Подобранная сетка встаёт перед пустым хвостом', () {
    // После вложения в конце разбор оставляет пустой абзац — в него пишут
    // дальше, поэтому он должен остаться последним.
    final blocks = EditorDocument.parse(MarkdownLite.mediaToken('a'));
    EditorDocument.adopt(blocks, ['b'], newBlock: TextBlock.new);

    expect(blocks.last, isA<TextBlock>());
    expect(blocks.whereType<TextBlock>().last.isEmpty, isTrue);
  });

  test('Без потерянных вложений запись не трогается', () {
    final blocks = EditorDocument.parse('Просто текст.');
    EditorDocument.adopt(blocks, const [], newBlock: TextBlock.new);
    expect(blocks.length, 1);
  });
}

void _reorderTests() {
  // Порядок блоков меняется удержанием. Индексы у перетаскивания коварные:
  // позиция вставки приходит ДО удаления элемента.
  group('Перестановка блоков', () {
    List<String> headings(List<EditorBlock> blocks) => [
          for (final b in blocks)
            if (b is TextBlock) b.title.text else 'media',
        ];

    List<EditorBlock> three() => [
          TextBlock(heading: 'А'),
          TextBlock(heading: 'Б'),
          TextBlock(heading: 'В'),
        ];

    test('Блок едет вниз', () {
      final blocks = three();
      EditorDocument.reorder(blocks, 0, 2);
      expect(headings(blocks), ['Б', 'А', 'В']);
    });

    test('Блок едет в самый низ', () {
      final blocks = three();
      EditorDocument.reorder(blocks, 0, 3);
      expect(headings(blocks), ['Б', 'В', 'А']);
    });

    test('Блок едет вверх', () {
      final blocks = three();
      EditorDocument.reorder(blocks, 2, 0);
      expect(headings(blocks), ['В', 'А', 'Б']);
    });

    test('Текст и вложения переезжают вместе с блоком', () {
      final blocks = <EditorBlock>[
        TextBlock(heading: 'А', text: 'первый'),
        MediaBlock(['m1']),
      ];
      EditorDocument.reorder(blocks, 1, 0);
      expect(headings(blocks), ['media', 'А']);
      expect((blocks[1] as TextBlock).controller.text, 'первый');
    });

    test('Мимо списка ничего не ломает', () {
      final blocks = three();
      EditorDocument.reorder(blocks, 7, 0);
      expect(headings(blocks), ['А', 'Б', 'В']);
    });
  });
}
