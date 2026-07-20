import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/theme/icon_keys.dart';

/// Сторож реестра иконок.
///
/// Ключ иконки лежит в базе строкой и ездит по синку, поэтому расхождение
/// между картой [AppIcons.all] и группами выбора ничего не роняет — оно молча
/// подсовывает человеку `Icons.circle_outlined` вместо выбранного значка.
void main() {
  final grouped = [for (final g in AppIcons.groups) ...g];

  test('Каждая иконка группы есть в реестре', () {
    final unknown = grouped.where((k) => !AppIcons.all.containsKey(k)).toList();
    expect(unknown, isEmpty, reason: 'в сетке выбора покажется заглушка');
  });

  test('Иконка не повторяется в двух группах', () {
    final seen = <String>{};
    final twice = grouped.where((k) => !seen.add(k)).toList();
    expect(twice, isEmpty, reason: 'одна и та же иконка в списке дважды');
  });

  test('Реестр показан целиком: иконок вне групп нет', () {
    final orphans =
        AppIcons.all.keys.where((k) => !grouped.contains(k)).toList();
    expect(orphans, isEmpty, reason: 'иконка есть, но выбрать её негде');
  });

  test('Ходовой ряд редакторов набирается из реестра', () {
    final unknown =
        AppIcons.pickerOrder.where((k) => !AppIcons.all.containsKey(k));
    expect(unknown, isEmpty);
    // Редактор дневника показывает первые шестнадцать, трекера — двадцать.
    expect(AppIcons.pickerOrder.length, greaterThanOrEqualTo(20));
  });

  test('Неизвестный ключ падает в заглушку, а не роняет экран', () {
    expect(AppIcons.resolve('нет-такого'), AppIcons.fallback);
    expect(AppIcons.resolve(null), AppIcons.fallback);
  });
}
