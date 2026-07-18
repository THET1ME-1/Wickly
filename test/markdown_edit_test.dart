import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/utils/markdown_edit.dart';

TextSelection sel(int a, [int? b]) =>
    TextSelection(baseOffset: a, extentOffset: b ?? a);

void main() {
  group('Парные символы', () {
    test('Оборачивают выделение', () {
      final r = MarkdownEdit.toggleInline('вода тёплая', sel(0, 4), '**');
      expect(r.text, '**вода** тёплая');
      expect(r.selection.start, 2);
      expect(r.selection.end, 6);
    });

    test('Снимают обёртку, если она уже стоит внутри выделения', () {
      final r = MarkdownEdit.toggleInline('**вода** тёплая', sel(0, 8), '**');
      expect(r.text, 'вода тёплая');
    });

    test('Снимают обёртку вокруг выделения', () {
      final r = MarkdownEdit.toggleInline('**вода** тёплая', sel(2, 6), '**');
      expect(r.text, 'вода тёплая');
    });

    test('Без выделения ставят пустую пару и курсор внутрь', () {
      final r = MarkdownEdit.toggleInline('текст', sel(5), '*');
      expect(r.text, 'текст**');
      expect(r.selection.baseOffset, 6);
    });
  });

  group('Приставки строк', () {
    test('Чеклист ставится на все выделенные строки', () {
      final r = MarkdownEdit.togglePrefix(
          'плед\nплёнка', sel(0, 11), '- [ ] ');
      expect(r.text, '- [ ] плед\n- [ ] плёнка');
    });

    test('Повторное нажатие снимает приставку', () {
      final r = MarkdownEdit.togglePrefix(
          '- [ ] плед\n- [ ] плёнка', sel(0, 23), '- [ ] ');
      expect(r.text, 'плед\nплёнка');
    });

    test('Отмеченный пункт тоже считается чеклистом', () {
      final r =
          MarkdownEdit.togglePrefix('- [x] плед', sel(0, 10), '- [ ] ');
      expect(r.text, 'плед');
    });

    test('Заголовок заменяет список, а не липнет к нему', () {
      final r = MarkdownEdit.togglePrefix('- пункт', sel(0, 7), '# ');
      expect(r.text, '# пункт');
    });

    test('Смешанное выделение выравнивается по приставке', () {
      final r = MarkdownEdit.togglePrefix('- один\nдва', sel(0, 10), '- ');
      expect(r.text, '- один\n- два');
    });
  });

  group('Продолжение списка', () {
    test('Enter в пункте даёт следующий пункт', () {
      final r = MarkdownEdit.continueList('- плед', sel(6));
      expect(r!.text, '- плед\n- ');
      expect(r.selection.baseOffset, 9);
    });

    test('Отмеченный пункт продолжается пустым', () {
      final r = MarkdownEdit.continueList('- [x] плед', sel(10));
      expect(r!.text, '- [x] плед\n- [ ] ');
    });

    test('Пустой пункт прерывает список', () {
      final r = MarkdownEdit.continueList('- один\n- ', sel(9));
      expect(r!.text, '- один\n');
    });

    test('Нумерованный список считает дальше', () {
      final r = MarkdownEdit.continueList('3. третий', sel(9));
      expect(r!.text, '3. третий\n4. ');
    });

    test('Обычная строка не трогается', () {
      expect(MarkdownEdit.continueList('просто текст', sel(12)), isNull);
    });
  });

  test('Вставка на место курсора', () {
    final r = MarkdownEdit.insert('вода ', sel(5), 'тёплая');
    expect(r.text, 'вода тёплая');
    expect(r.selection.baseOffset, 11);
  });
}
