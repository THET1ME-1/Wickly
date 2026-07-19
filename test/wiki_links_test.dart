import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/services/wiki_links.dart';
import 'package:wickly/widgets/markdown_lite.dart';

/// Ссылки между записями: `[[Вечер у реки]]`.
void main() {
  Entry entry({
    required String id,
    String? title,
    String? body,
    DateTime? at,
  }) =>
      Entry(
        id: id,
        journalId: 'j',
        title: title,
        body: body,
        entryDate: at ?? DateTime(2026, 7, 17),
        createdAt: at ?? DateTime(2026, 7, 17),
      );

  test('Цели вынимаются по порядку и без повторов', () {
    const body = 'Начал с [[Вечер у реки]], потом опять [[вечер у реки]] '
        'и ещё [[Утро, кофе, планы]].';

    expect(
      WikiLinks.targetsIn(body),
      ['Вечер у реки', 'Утро, кофе, планы'],
    );
  });

  test('Скобки и переносы строк ссылкой не считаются', () {
    expect(WikiLinks.targetsIn('текст [[ ]] и [[]]'), isEmpty);
    expect(WikiLinks.targetsIn('[[первая\nвторая]]'), isEmpty);
  });

  test('Регистр и лишние пробелы при поиске не важны', () {
    final target = entry(id: '1', title: 'Вечер у реки');
    final found = WikiLinks.resolve('  вечер   У   реки ', [target]);

    expect(found?.id, '1');
  });

  test('Из одинаковых названий берётся свежее', () {
    final old = entry(id: 'old', title: 'Бег', at: DateTime(2025, 5, 1));
    final fresh = entry(id: 'fresh', title: 'Бег', at: DateTime(2026, 7, 1));

    expect(WikiLinks.resolve('Бег', [old, fresh])?.id, 'fresh');
  });

  test('Запись без заголовка ищется по первой строке', () {
    final e = entry(id: '1', body: 'Дошли до старого моста, вода тёплая.');

    expect(WikiLinks.titleOf(e), 'Дошли до старого моста, вода тёплая.');
    expect(
      WikiLinks.resolve('Дошли до старого моста, вода тёплая.', [e])?.id,
      '1',
    );
  });

  test('Пустая запись целью ссылки быть не может', () {
    expect(WikiLinks.titleOf(entry(id: '1')), isNull);
    expect(WikiLinks.resolve('', [entry(id: '1')]), isNull);
  });

  test('Упоминания: кто ссылается на запись, свежие сверху', () {
    final target = entry(id: 'target', title: 'Вечер у реки');
    final may = entry(
      id: 'may',
      title: 'Май',
      body: 'Вспомнил [[Вечер у реки]]',
      at: DateTime(2026, 5, 2),
    );
    final june = entry(
      id: 'june',
      title: 'Июнь',
      body: 'Опять [[вечер у реки]] — и снова хорошо',
      at: DateTime(2026, 6, 2),
    );
    final other = entry(id: 'other', title: 'Другое', body: 'Без ссылок');

    final links = WikiLinks.backlinks(target, [may, june, other, target]);

    expect(links.map((e) => e.id), ['june', 'may']);
  });

  test('Ссылка на саму себя в упоминания не попадает', () {
    final self = entry(
      id: 'self',
      title: 'Круг',
      body: 'Смотри [[Круг]]',
    );

    expect(WikiLinks.backlinks(self, [self]), isEmpty);
  });

  test('В выжимке текста от ссылки остаётся название', () {
    expect(
      MarkdownLite.strip('Продолжение [[Вечер у реки]] на новый лад'),
      'Продолжение Вечер у реки на новый лад',
    );
  });
}
