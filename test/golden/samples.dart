import 'package:wickly/models/entry.dart';
import 'package:wickly/models/media.dart';
import 'package:wickly/services/stats_service.dart';
import 'package:wickly/widgets/entry_card.dart';

/// Данные для снимков экранов — тот же материал, что в макете, чтобы снимок
/// можно было приложить к макету и сравнить глазами.
class Samples {
  const Samples._();

  /// «Сегодня» в снимках зафиксировано: иначе картинки менялись бы каждый день.
  static final today = DateTime(2026, 7, 17, 21, 41);

  static Entry entry({
    required String id,
    String? title,
    String? body,
    required DateTime at,
    int? mood,
    String? place,
    String? weather,
    double? temp,
    bool favorite = false,
    bool pinned = false,
  }) =>
      Entry(
        id: id,
        journalId: 'default',
        title: title,
        body: body,
        entryDate: at,
        createdAt: at,
        mood: mood,
        place: place,
        weather: weather,
        temp: temp,
        favorite: favorite,
        pinned: pinned,
        wordCount: 142,
        writeMs: 132000,
      );

  static Media photo(String entryId, {String id = 'm1'}) => Media(
        id: id,
        entryId: entryId,
        kind: MediaKind.photo,
        file: 'нет-файла.jpg',
        createdAt: today,
      );

  /// Лента: вечерняя запись с обложкой, утренняя без неё, вчерашний день.
  static List<EntryCardItem> feedItems() => [
        EntryCardItem(
          entry: entry(
            id: 'e-river',
            title: 'Вечер у реки',
            body: 'Дошли до старого моста, вода ещё тёплая. '
                '**Долго сидели молча** и смотрели, как темнеет над водой.',
            at: DateTime(2026, 7, 17, 21, 10),
            mood: 4,
            place: 'Набережная',
            weather: 'ясно',
            temp: 24,
          ),
          cover: photo('e-river'),
          mediaCount: 5,
          tags: const ['прогулка', 'лето'],
        ),
        EntryCardItem(
          entry: entry(
            id: 'e-morning',
            title: 'Утро, кофе, планы',
            body: 'Проснулся раньше будильника. Записал три цели на день, '
                'и день сразу стал понятнее.',
            at: DateTime(2026, 7, 17, 7, 40),
            mood: 5,
            place: 'Дом',
          ),
          tags: const ['цели'],
        ),
        EntryCardItem(
          entry: entry(
            id: 'e-work',
            title: 'Долгий созвон',
            body: 'Три часа спорили о том, что решается за десять минут.',
            at: DateTime(2026, 7, 16, 19, 5),
            mood: 2,
          ),
          mediaCount: 1,
        ),
      ];

  /// Воспоминание «в этот день» из позапрошлых лет.
  static List<EntryCardItem> memories() => [
        EntryCardItem(
          entry: entry(
            id: 'e-flat',
            title: 'Первый день в новой квартире',
            body: 'Коробки, пустые стены и странное счастье. Кажется, это дом.',
            at: DateTime(2023, 7, 17, 20, 0),
            mood: 5,
          ),
          cover: photo('e-flat', id: 'm-flat'),
        ),
      ];

  static const streak = Streak(current: 12, best: 21, writtenToday: true);

  /// Месяц записей с настроением — для календаря и статистики.
  static List<Entry> month() {
    final out = <Entry>[];
    const moods = [4, 3, 5, 4, 4, 2, 3, 5, 4, 5, 3, 4, 5, 4, 2, 4, 4];
    for (var i = 0; i < moods.length; i++) {
      final day = DateTime(2026, 7, i + 1, 20);
      out.add(entry(
        id: 'm$i',
        title: 'День ${i + 1}',
        body: 'Запись дня ${i + 1}.',
        at: day,
        mood: moods[i],
        weather: i % 3 == 0 ? 'ясно' : (i % 3 == 1 ? 'облачно' : 'дождь'),
      ));
    }
    return out;
  }
}
