import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:wickly/services/import_service.dart';

/// Прогон парсеров импорта на настоящих файлах экспорта — как `db_smoke` и
/// `sync_smoke`, но без Flutter и без базы: только разбор.
///
/// Пути к образцам передаются аргументами (по умолчанию — из «Загрузки»).
void main(List<String> args) {
  final tg = args.isNotEmpty
      ? args[0]
      : '/home/alelx/Загрузки/Telegram Desktop';

  var failed = 0;
  void check(bool ok, String label) {
    print('  ${ok ? '✓' : '✗'} $label');
    if (!ok) failed++;
  }

  print('— Diaro —');
  try {
    final zip = File('$tg/Diaro_auto_20250801.zip').readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(zip);
    final xml = utf8.decode(
        archive.files.firstWhere((f) => f.name.endsWith('.xml')).content
            as List<int>);
    final b = ImportService.parseDiaro(xml);
    print('  журналов=${b.journals.length} записей=${b.entryCount} '
        'вложений=${b.mediaCount}');
    for (final j in b.journals) {
      print('    «${j.name}» color=${j.color} записей=${j.entries.length}');
    }
    check(b.entryCount > 0, 'записи разобраны');
    final withMood = b.journals
        .expand((j) => j.entries)
        .where((e) => e.mood != null)
        .toList();
    check(withMood.every((e) => e.mood! >= 1 && e.mood! <= 5),
        'настроение в шкале 1..5');
    final withTags =
        b.journals.expand((j) => j.entries).where((e) => e.tags.isNotEmpty);
    check(withTags.isNotEmpty, 'теги привязаны');
    final sample = b.journals
        .expand((j) => j.entries)
        .firstWhere((e) => (e.title ?? '').isNotEmpty, orElse: () => b.journals.first.entries.first);
    print('    пример: "${sample.title}" ${sample.date} mood=${sample.mood} '
        'tags=${sample.tags.take(3).toList()} place=${sample.place} '
        'temp=${sample.temp}');
  } catch (e) {
    check(false, 'Diaro разобрался без ошибок ($e)');
  }

  print('\n— StoryPad —');
  try {
    final jsonFile = Directory(tg)
        .listSync()
        .whereType<File>()
        .firstWhere((f) =>
            f.path.contains('StoryPad') && f.path.endsWith('.json'));
    final b = ImportService.parseStoryPad(jsonFile.readAsStringSync());
    print('  журналов=${b.journals.length} записей=${b.entryCount} '
        'вложений=${b.mediaCount}');
    check(b.entryCount > 0, 'записи разобраны');
    final entries = b.journals.expand((j) => j.entries).toList();
    check(entries.every((e) => e.date.year > 2000), 'даты собраны из полей');
    final bodies = entries.where((e) => (e.body ?? '').isNotEmpty).toList();
    check(bodies.isNotEmpty, 'текст извлечён из latest_content');
    check(entries.any((e) => e.media.isNotEmpty), 'вложения привязаны');
    check(entries.any((e) => e.mood != null), 'настроение размечено');
    final s = bodies.first;
    print('    пример: "${s.title}" ${s.date} mood=${s.mood} '
        'вложений=${s.media.length} текст="${_short(s.body)}"');
    final withMedia =
        entries.firstWhere((e) => e.media.isNotEmpty, orElse: () => entries.first);
    if (withMedia.media.isNotEmpty) {
      print('    файл вложения: ${withMedia.media.first.sourceName} '
          '(${withMedia.media.first.kind.name})');
    }
  } catch (e, st) {
    check(false, 'StoryPad разобрался без ошибок ($e)');
    print(st);
  }

  print('\n${failed == 0 ? 'всё разобрано' : '$failed проверок провалено'}');
  if (failed > 0) exit(1);
}

String _short(String? s) {
  if (s == null) return '';
  final one = s.replaceAll('\n', ' ');
  return one.length <= 60 ? one : '${one.substring(0, 60)}…';
}
