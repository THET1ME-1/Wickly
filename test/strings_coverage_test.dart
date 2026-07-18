import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Сторож словаря.
///
/// В листе обновления на живом устройстве вместо текста показались сырые
/// ключи: `update_new_version`, `update_downloading`. Их забыли внести в
/// словарь, а `tr()` в таком случае возвращает сам ключ. Снимки экрана этого
/// не ловят: тот лист в них не попадает.
///
/// Проверяем по исходникам, а не через `tr()`: у части ключей английский
/// перевод совпадает с самим ключом («today» → «today»), и сравнение
/// результата с ключом объявило бы их пропавшими.
void main() {
  const languages = ['ru', 'en', 'de', 'fr', 'es', 'it', 'pt'];
  final keyCall = RegExp(r"""\btrf?\(\s*'([a-z0-9_]+)'""");
  final keyDecl = RegExp(r"""^  '([a-z0-9_]+)':\s*\{""", multiLine: true);

  Iterable<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  final dictionary = <String, String>{};
  for (final file in dartFiles('lib/l10n/dict')) {
    final text = file.readAsStringSync();
    final matches = keyDecl.allMatches(text).toList();
    for (var i = 0; i < matches.length; i++) {
      final from = matches[i].end;
      final to = i + 1 < matches.length ? matches[i + 1].start : text.length;
      dictionary[matches[i].group(1)!] = text.substring(from, to);
    }
  }

  final used = <String>{};
  for (final file in dartFiles('lib')) {
    if (file.path.contains('/l10n/')) continue;
    for (final m in keyCall.allMatches(file.readAsStringSync())) {
      used.add(m.group(1)!);
    }
  }

  test('Словарь вообще разобрался', () {
    expect(dictionary.length, greaterThan(200));
    expect(used.length, greaterThan(100));
  });

  test('Каждый ключ из кода есть в словаре', () {
    final missing = used.where((k) => !dictionary.containsKey(k)).toList()
      ..sort();
    expect(missing, isEmpty,
        reason: 'нет перевода — на экране покажется сырой ключ');
  });

  test('Каждый ключ переведён на все семь языков', () {
    final gaps = <String>[];
    for (final key in used) {
      final body = dictionary[key];
      if (body == null) continue;
      for (final lang in languages) {
        if (!body.contains("'$lang':")) gaps.add('$key → $lang');
      }
    }
    gaps.sort();
    expect(gaps, isEmpty, reason: 'язык без перевода показывает сырой ключ');
  });
}
