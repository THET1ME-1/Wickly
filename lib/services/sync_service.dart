import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../data/crypto.dart';
import '../data/db.dart';
import '../data/media_store.dart';

/// Что приехало при слиянии.
class MergeReport {
  final int rows;
  final int files;

  const MergeReport({required this.rows, required this.files});

  bool get isEmpty => rows == 0 && files == 0;
}

/// Синхронизация между своими устройствами.
///
/// Слияние идёт по CRDT: у каждой строки есть логические часы (HLC) и метка
/// устройства, поэтому «кто последний, тот и прав» решается на уровне строки,
/// а не файла. Из этого следует главное свойство: **порядок обмена не важен**,
/// и один и тот же пакет можно применить дважды без вреда.
///
/// Пакет — это JSON с изменениями плюс вложения, которых нет у той стороны.
/// Он шифруется общим секретом пары устройств, поэтому его не страшно класть
/// в общую папку Syncthing или гонять по домашней сети.
class SyncService {
  const SyncService._();

  /// Версия формата пакета. Меняется, когда меняется структура — чтобы старое
  /// устройство честно сказало «не понимаю», а не молча сломало базу.
  static const formatVersion = 1;

  /// Собирает пакет изменений с момента [since].
  ///
  /// `null` в [since] означает «всё с начала времён» — так выглядит первая
  /// синхронизация с новым устройством.
  static Future<Map<String, Object?>> buildPacket({Hlc? since}) async {
    final changeset = await Db.crdt.getChangeset(modifiedAfter: since);

    // Имена вложений, на которые ссылаются приехавшие строки: пересылаем
    // только их, а не весь склад.
    final files = <String>{};
    for (final rows in changeset.values) {
      for (final row in rows) {
        final file = row['file'];
        final thumb = row['thumb'];
        if (file is String) files.add(file);
        if (thumb is String) files.add(thumb);
      }
    }

    final media = <String, String>{};
    for (final name in files) {
      final bytes = await MediaStore.instance.readRaw(name);
      if (bytes != null) media[name] = base64Encode(bytes);
    }

    return {
      'v': formatVersion,
      'node': Db.crdt.nodeId,
      'at': DateTime.now().toIso8601String(),
      'changeset': changeset.map(
        (table, rows) => MapEntry(table, rows.map(_encodeRow).toList()),
      ),
      'media': media,
    };
  }

  /// Применяет пакет к своей базе.
  static Future<MergeReport> applyPacket(Map<String, Object?> packet) async {
    final version = (packet['v'] as num?)?.toInt() ?? 0;
    if (version > formatVersion) {
      throw const FormatException('Пакет собран более новой версией Wickly');
    }

    // Сперва файлы: строка про фото не должна появиться раньше самого фото,
    // иначе лента мигнёт пустой обложкой.
    var fileCount = 0;
    final media = (packet['media'] as Map?)?.cast<String, Object?>() ?? {};
    for (final entry in media.entries) {
      final bytes = base64Decode(entry.value as String);
      await MediaStore.instance.writeRaw(entry.key, bytes);
      fileCount++;
    }

    final raw = (packet['changeset'] as Map?)?.cast<String, Object?>() ?? {};
    final changeset = <String, List<Map<String, Object?>>>{};
    var rowCount = 0;
    for (final entry in raw.entries) {
      final rows = (entry.value as List)
          .map((r) => _decodeRow((r as Map).cast<String, Object?>()))
          .toList();
      changeset[entry.key] = rows;
      rowCount += rows.length;
    }

    if (changeset.isNotEmpty) await Db.crdt.merge(changeset);
    return MergeReport(rows: rowCount, files: fileCount);
  }

  /// Пакет в зашифрованные байты: то, что кладётся в файл или уходит в сокет.
  static Future<List<int>> sealPacket(
    Map<String, Object?> packet,
    SecretKey key,
  ) =>
      Crypto.instance
          .encryptBytesWith(utf8.encode(jsonEncode(packet)), key);

  static Future<Map<String, Object?>> openPacket(
    List<int> sealed,
    SecretKey key,
  ) async {
    final clear = await Crypto.instance.decryptBytesWith(sealed, key);
    return (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>();
  }

  /// Ключ пары устройств из фразы сопряжения.
  ///
  /// Соль привязана к самой фразе, а не случайна: обе стороны должны получить
  /// один ключ, зная только фразу, и никакого канала для обмена солью нет.
  static Future<SecretKey> keyFromPhrase(String phrase) {
    final normalized = phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final salt = hash.sha256.convert(utf8.encode('wickly-pair:$normalized')).bytes;
    return Crypto.keyFromPassphrase(normalized, salt);
  }

  /// Фраза сопряжения: четыре слова, которые легко продиктовать вслух.
  static String generatePhrase() {
    final random = SecretKeyData.random(length: 8).bytes;
    return [
      for (var i = 0; i < 4; i++) _words[random[i] % _words.length],
    ].join('-');
  }

  /// Небольшой словарь коротких слов без похожих написаний.
  static const _words = [
    'море', 'лампа', 'кедр', 'ветер', 'сокол', 'мост', 'дюна', 'клён',
    'парус', 'янтарь', 'иней', 'фитиль', 'озеро', 'горн', 'вереск', 'смола',
  ];

  /// Колонки CRDT, которые в базе — логические часы, а в JSON — строки.
  static const _clockColumns = {'hlc', 'modified'};

  /// В JSON нет ни часов, ни дат: наружу они уходят строками.
  static Map<String, Object?> _encodeRow(Map<String, Object?> row) => {
        for (final e in row.entries)
          e.key: switch (e.value) {
            final DateTime d => d.toIso8601String(),
            final Hlc h => h.toString(),
            _ => e.value,
          },
      };

  /// Обратно: часы разбираем в [Hlc], иначе слияние отвергнет пакет — оно
  /// сверяет порядок именно по ним, а не по строкам.
  static Map<String, Object?> _decodeRow(Map<String, Object?> row) => {
        for (final e in row.entries)
          e.key: _clockColumns.contains(e.key) && e.value is String
              ? Hlc.parse(e.value as String)
              : e.value,
      };
}

/// Обмен пакетами через файлы в общей папке.
///
/// Это «режим Syncthing»: приложение кладёт свой пакет и читает чужие, а
/// доставкой занимается сама папка. **Живой файл базы через Syncthing гонять
/// нельзя** — WAL и частичные записи убивают базу; поэтому наружу уходят
/// только пакеты изменений.
class SyncFolder {
  const SyncFolder._();

  static const fileSuffix = '.wickly-sync';

  /// Пишет свой пакет в папку. Имя включает узел, поэтому устройства не
  /// затирают файлы друг друга.
  static Future<File> writePacket(
    Directory folder,
    List<int> sealed,
    String nodeId,
  ) async {
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final file = File('${folder.path}/$nodeId$fileSuffix');
    await file.writeAsBytes(sealed, flush: true);
    return file;
  }

  /// Чужие пакеты из папки (свой пропускаем).
  static List<File> foreignPackets(Directory folder, String nodeId) {
    if (!folder.existsSync()) return const [];
    return folder
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith(fileSuffix) && !f.path.contains('$nodeId$fileSuffix'))
        .toList();
  }
}
