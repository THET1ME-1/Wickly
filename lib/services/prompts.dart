import '../l10n/strings.dart';

/// Журнальные подсказки: вопросы, с которых легко начать запись.
///
/// Наборов пять, по пять вопросов — их хватает, чтобы вопрос не повторялся
/// неделю. Вопрос дня выбирается по дате, а не случайно: иначе он менялся бы
/// при каждом открытии экрана, и на него невозможно было бы «вернуться позже».
class Prompts {
  const Prompts._();

  static const packs = ['gratitude', 'reflection', 'goals', 'relations', 'creative'];

  static const _perPack = 5;

  /// Название набора на языке интерфейса.
  static String packLabel(String pack) => tr('pack_$pack');

  /// Все вопросы набора.
  static List<String> of(String pack) => [
        for (var i = 1; i <= _perPack; i++) tr('prompt_${pack}_$i'),
      ];

  /// Ключ вопроса дня — по нему запись помнит, с чего началась.
  static String keyOfDay(String pack, DateTime day) {
    final index = (_dayNumber(day) % _perPack) + 1;
    return 'prompt_${pack}_$index';
  }

  /// Вопрос дня.
  static String ofDay(String pack, DateTime day) => tr(keyOfDay(pack, day));

  /// Следующий вопрос из набора — кнопка «Другая».
  static String next(String pack, String currentKey) {
    final all = [
      for (var i = 1; i <= _perPack; i++) 'prompt_${pack}_$i',
    ];
    final at = all.indexOf(currentKey);
    return all[(at + 1) % all.length];
  }

  static int _dayNumber(DateTime d) =>
      d.difference(DateTime(2020)).inDays.abs();
}
