import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/services/search_service.dart';

Entry _e({
  String? title,
  String? body,
  DateTime? at,
  int? mood,
  String? place,
}) =>
    Entry.create(journalId: 'j', title: title, body: body, entryDate: at, mood: mood)
        .copyWith(place: place);

void main() {
  final entries = [
    _e(
      title: 'Вечер у реки',
      body: 'Дошли до старого **моста**, вода ещё тёплая.',
      at: DateTime(2026, 7, 17),
      mood: 4,
      place: 'Набережная',
    ),
    _e(
      title: 'Поездка в Питер',
      body: 'Прошли под мостом на катере.',
      at: DateTime(2026, 5, 3),
      mood: 5,
      place: 'Нева',
    ),
    _e(
      title: 'Дома',
      body: 'Ничего особенного.',
      at: DateTime(2025, 1, 9),
      mood: 2,
    ),
  ];

  test('Находит по тексту записи без учёта разметки', () async {
    final r = await SearchService.search(entries, 'моста');
    expect(r.entries.length, 1);
    expect(r.entries.first.entry.title, 'Вечер у реки');
    expect(r.entries.first.snippet.contains('**'), false);
  });

  test('Находит по заголовку и по месту', () async {
    expect((await SearchService.search(entries, 'питер')).entries.length, 1);
    expect((await SearchService.search(entries, 'набережная')).entries.length, 1);
  });

  test('Регистр не важен', () async {
    expect((await SearchService.search(entries, 'ВЕЧЕР')).entries.length, 1);
  });

  test('Отрывок отмечает место совпадения', () async {
    final hit = (await SearchService.search(entries, 'вода')).entries.first;
    final at = hit.matchStart;
    expect(at >= 0, true);
    expect(hit.snippet.substring(at, at + hit.matchLength).toLowerCase(), 'вода');
  });

  test('Фильтр по настроению', () async {
    final r = await SearchService.search(entries, '',
        filters: const SearchFilters(mood: 5));
    expect(r.entries.length, 1);
    expect(r.entries.first.entry.title, 'Поездка в Питер');
  });

  test('Фильтр по году', () async {
    final r = await SearchService.search(entries, '',
        filters: const SearchFilters(year: 2025));
    expect(r.entries.length, 1);
    expect(r.entries.first.entry.title, 'Дома');
  });

  test('Текст и фильтр работают вместе', () async {
    final r = await SearchService.search(entries, 'мост',
        filters: const SearchFilters(year: 2026, mood: 4));
    expect(r.entries.length, 1);
    expect(r.entries.first.entry.place, 'Набережная');
  });

  test('Пустой запрос без фильтров ничего не ищет', () async {
    expect((await SearchService.search(entries, '  ')).isEmpty, true);
  });

  test('Ничего не найдено — пустой результат, а не ошибка', () async {
    expect((await SearchService.search(entries, 'вертолёт')).isEmpty, true);
  });
}
