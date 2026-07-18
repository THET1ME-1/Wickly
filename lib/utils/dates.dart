import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../l10n/locale_controller.dart';
import '../l10n/strings.dart';

/// Даты и время на языке интерфейса.
///
/// Приложение живёт на семи языках, поэтому названия месяцев и дней недели
/// берём у `intl` по коду текущего языка, а не собираем руками. Символы дат
/// нужно один раз загрузить — [init] вызывается из `main` до первого кадра.
class Dates {
  const Dates._();

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    await initializeDateFormatting();
    _ready = true;
  }

  static String get _loc => LocaleController.instance.code;

  /// «21:41»
  static String time(DateTime d) => DateFormat.Hm(_loc).format(d);

  /// «четверг, 17 июля». Без заглавной: в русском день недели пишется строчной,
  /// и в макете он такой же.
  static String dayLong(DateTime d) =>
      DateFormat('EEEE, d MMMM', _loc).format(d);

  /// «чт 17 июля»
  static String dayShort(DateTime d) =>
      _capitalize(DateFormat('EEE d MMMM', _loc).format(d));

  /// «17 июля»
  static String dayMonth(DateTime d) => DateFormat('d MMMM', _loc).format(d);

  /// «июль 2026»
  static String monthYear(DateTime d) =>
      _capitalize(DateFormat('LLLL yyyy', _loc).format(d));

  /// «17 июля 2023»
  static String full(DateTime d) => DateFormat('d MMMM yyyy', _loc).format(d);

  /// Однобуквенные шапки календаря, с понедельника: Пн Вт Ср…
  static List<String> weekdayHeaders() {
    final base = DateTime(2026, 6, 1); // понедельник
    return [
      for (var i = 0; i < 7; i++)
        _capitalize(
            DateFormat('EEE', _loc).format(base.add(Duration(days: i)))),
    ];
  }

  /// «сегодня» / «вчера» / «17 июля» — для подписей карточек.
  static String relativeDay(DateTime d, {DateTime? now}) {
    final today = _midnight(now ?? DateTime.now());
    final that = _midnight(d);
    final diff = today.difference(that).inDays;
    if (diff == 0) return tr('today');
    if (diff == 1) return tr('yesterday');
    return dayMonth(d);
  }

  /// «3 года назад» — подпись воспоминания.
  static String yearsAgo(int years) => switch (_loc) {
        'ru' => '$years ${_ruPlural(years, 'год', 'года', 'лет')} назад',
        'de' => 'vor $years ${years == 1 ? 'Jahr' : 'Jahren'}',
        'fr' => 'il y a $years ${years == 1 ? 'an' : 'ans'}',
        'es' => 'hace $years ${years == 1 ? 'año' : 'años'}',
        'it' => '$years ${years == 1 ? 'anno' : 'anni'} fa',
        'pt' => 'há $years ${years == 1 ? 'ano' : 'anos'}',
        _ => '$years ${years == 1 ? 'year' : 'years'} ago',
      };

  /// «12 дней подряд» — серия.
  static String daysStreak(int days) => switch (_loc) {
        'ru' => '$days ${_ruPlural(days, 'день', 'дня', 'дней')} подряд',
        'de' => '$days Tage in Folge',
        'fr' => '$days jours d’affilée',
        'es' => '$days días seguidos',
        'it' => '$days giorni di fila',
        'pt' => '$days dias seguidos',
        _ => '$days days in a row',
      };

  /// «128 записей» — счётчик записей с правильным окончанием.
  static String entryCount(int n) => switch (_loc) {
        'ru' => '$n ${_ruPlural(n, 'запись', 'записи', 'записей')}',
        'de' => '$n ${n == 1 ? 'Eintrag' : 'Einträge'}',
        'fr' => '$n ${n == 1 ? 'entrée' : 'entrées'}',
        'es' => '$n ${n == 1 ? 'entrada' : 'entradas'}',
        'it' => '$n ${n == 1 ? 'voce' : 'voci'}',
        'pt' => '$n ${n == 1 ? 'anotação' : 'anotações'}',
        _ => '$n ${n == 1 ? 'entry' : 'entries'}',
      };

  /// «142 слова».
  static String wordCount(int n) => switch (_loc) {
        'ru' => '$n ${_ruPlural(n, 'слово', 'слова', 'слов')}',
        'de' => '$n ${n == 1 ? 'Wort' : 'Wörter'}',
        'fr' => '$n ${n == 1 ? 'mot' : 'mots'}',
        'es' => '$n ${n == 1 ? 'palabra' : 'palabras'}',
        'it' => '$n ${n == 1 ? 'parola' : 'parole'}',
        'pt' => '$n ${n == 1 ? 'palavra' : 'palavras'}',
        _ => '$n ${n == 1 ? 'word' : 'words'}',
      };

  /// «~2 мин» — сколько человек писал запись.
  static String minutes(int ms) {
    final m = (ms / 60000).round();
    return switch (_loc) {
      'ru' => '~$m мин',
      'de' => '~$m Min.',
      'fr' => '~$m min',
      'es' => '~$m min',
      'it' => '~$m min',
      'pt' => '~$m min',
      _ => '~$m min',
    };
  }

  /// Русские окончания: 1 день, 2 дня, 5 дней.
  static String _ruPlural(int n, String one, String few, String many) {
    final mod100 = n % 100;
    if (mod100 >= 11 && mod100 <= 14) return many;
    return switch (n % 10) {
      1 => one,
      2 || 3 || 4 => few,
      _ => many,
    };
  }

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
