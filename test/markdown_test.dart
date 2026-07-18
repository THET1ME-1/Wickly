import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/widgets/markdown_lite.dart';

void main() {
  test('Блоки разбираются по видам', () {
    const src = '# Заголовок\n'
        'Обычный абзац.\n'
        '> цитата\n'
        '- пункт\n'
        '- [ ] дело\n'
        '- [x] сделано\n'
        '1. первый\n'
        '---';
    final blocks = MarkdownLite.parse(src);
    expect(blocks.map((b) => b.kind).toList(), [
      MdBlockKind.heading,
      MdBlockKind.paragraph,
      MdBlockKind.quote,
      MdBlockKind.bullet,
      MdBlockKind.todo,
      MdBlockKind.todo,
      MdBlockKind.numbered,
      MdBlockKind.divider,
    ]);
    expect(blocks[4].checked, false);
    expect(blocks[5].checked, true);
    expect(blocks[0].level, 1);
  });

  test('Превью очищается от разметки', () {
    const src = '# Вечер у реки\nДошли до **старого моста**, вода *тёплая*.';
    expect(MarkdownLite.strip(src),
        'Вечер у реки Дошли до старого моста, вода тёплая.');
  });

  test('Слова считаются по очищенному тексту', () {
    expect(MarkdownLite.wordCount('- [ ] взять **плед**'), 2);
    expect(MarkdownLite.wordCount(''), 0);
    expect(MarkdownLite.wordCount(null), 0);
  });

  test('Хэштеги вынимаются и не двоятся', () {
    const src = 'Гуляли #прогулка и снова #прогулка, потом #лето2026';
    expect(MarkdownLite.hashtags(src), ['прогулка', 'лето2026']);
  });

  test('Заголовок не путается с хэштегом', () {
    expect(MarkdownLite.hashtags('# Заголовок'), isEmpty);
  });

  test('Чеклист переключается в нужной строке', () {
    const src = '- [ ] взять плед\n- [ ] проявить плёнку';
    final after = MarkdownLite.toggleTodo(src, 0);
    expect(after, '- [x] взять плед\n- [ ] проявить плёнку');
    expect(MarkdownLite.toggleTodo(after, 0), src);
  });

  test('Переключение вне чеклиста ничего не ломает', () {
    const src = 'просто текст';
    expect(MarkdownLite.toggleTodo(src, 0), src);
    expect(MarkdownLite.toggleTodo(src, 99), src);
  });
}
