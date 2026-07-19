import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import '../data/crypto.dart';
import '../data/db.dart';
import '../data/media_store.dart';
import '../data/schema.dart';

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
      // Имя таблицы и имена колонок из пакета уходят в `merge` сырой
      // интерполяцией в SQL. Пропускаем только известные таблицы и строки,
      // где все ключи — обычные идентификаторы: чужое устройство не должно
      // мочь ни писать в произвольную таблицу, ни ломать структуру запроса.
      if (!Schema.knownTables.contains(entry.key)) continue;
      final rows = <Map<String, Object?>>[];
      for (final r in (entry.value as List)) {
        final row = (r as Map).cast<String, Object?>();
        if (row.keys.every(_isSafeColumn)) {
          rows.add(_decodeRow(row));
        }
      }
      if (rows.isEmpty) continue;
      changeset[entry.key] = rows;
      rowCount += rows.length;
    }

    if (changeset.isNotEmpty) await Db.crdt.merge(changeset);
    return MergeReport(rows: rowCount, files: fileCount);
  }

  /// Длина соли (байт), которую кладём в начало пакета.
  static const _saltLen = 16;

  /// Пакет в зашифрованные байты: то, что кладётся в файл или уходит в сокет.
  ///
  /// Формат: `соль(16) ‖ nonce‖ciphertext‖mac`. Соль СЛУЧАЙНА на каждый пакет и
  /// едет открыто рядом с шифртекстом — так ключ каждого пакета свой, и общую
  /// радужную таблицу «все фразы → ключ» построить нельзя. Обе стороны знают
  /// фразу, соль берут из принятого пакета.
  static Future<List<int>> sealForPhrase(
    Map<String, Object?> packet,
    String phrase,
  ) async {
    final salt = SecretKeyData.random(length: _saltLen).bytes;
    final key = await _phraseKey(phrase, salt);
    final body = await Crypto.instance
        .encryptBytesWith(utf8.encode(jsonEncode(packet)), key);
    return [...salt, ...body];
  }

  static Future<Map<String, Object?>> openWithPhrase(
    List<int> sealed,
    String phrase,
  ) async {
    if (sealed.length <= _saltLen) {
      throw const FormatException('Пакет короче соли');
    }
    final salt = sealed.sublist(0, _saltLen);
    final key = await _phraseKey(phrase, salt);
    final clear =
        await Crypto.instance.decryptBytesWith(sealed.sublist(_saltLen), key);
    return (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>();
  }

  /// Ключ пары устройств из фразы сопряжения и соли пакета (PBKDF2).
  static Future<SecretKey> _phraseKey(String phrase, List<int> salt) {
    final normalized =
        phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return Crypto.keyFromPassphrase(normalized, salt);
  }

  /// Фраза сопряжения: шесть разных слов, которые легко продиктовать вслух.
  ///
  /// Слова разные (повтор путает на слух) и берутся из большого словаря: пара
  /// слов из полутора десятков давала лишь ~15 бит — весь набор ключей можно
  /// было перебрать. Шесть слов из этого словаря — свыше сорока бит.
  static String generatePhrase() {
    final random = SecretKeyData.random(length: 64).bytes;
    final pool = [..._words];
    final picked = <String>[];
    for (var i = 0; picked.length < 6 && i < random.length; i++) {
      // Два байта на слово — индекс равномернее по большому словарю.
      final idx = ((random[i] << 8) | random[(i + 32) % random.length]) %
          pool.length;
      picked.add(pool.removeAt(idx));
    }
    return picked.join('-');
  }

  /// Словарь коротких, разных на слух слов для фразы сопряжения.
  static const _words = [
    'море', 'лампа', 'кедр', 'ветер', 'сокол', 'мост', 'дюна', 'клён',
    'парус', 'янтарь', 'иней', 'фитиль', 'озеро', 'горн', 'вереск', 'смола',
    'река', 'гора', 'туча', 'берег', 'камень', 'песок', 'волна', 'поле',
    'роса', 'гром', 'радуга', 'закат', 'рассвет', 'тропа', 'маяк', 'якорь',
    'весло', 'лодка', 'компас', 'карта', 'флаг', 'узел', 'мачта', 'каюта',
    'перо', 'свиток', 'книга', 'буква', 'слово', 'строка', 'глава', 'чернила',
    'кремень', 'уголь', 'пламя', 'искра', 'свеча', 'зола', 'дым', 'пепел',
    'барс', 'рысь', 'выдра', 'бобр', 'филин', 'аист', 'журавль', 'чайка',
    'ворон', 'грач', 'синица', 'снегирь', 'дуб', 'ясень', 'липа', 'рябина',
    'осина', 'берёза', 'сосна', 'пихта', 'тополь', 'верба', 'калина', 'ольха',
    'гранит', 'мрамор', 'кварц', 'агат', 'опал', 'топаз', 'оникс', 'нефрит',
    'овёс', 'ячмень', 'гречка', 'хмель', 'солод', 'руда', 'молот', 'клинок',
    'ножны', 'копьё', 'щит', 'шлем', 'кольчуга', 'колос', 'сноп', 'жнивьё',
  ];

  /// Имя колонки — обычный идентификатор. Всё прочее (пробелы, скобки,
  /// запятые) в имени означало бы попытку инъекции в SQL при слиянии.
  static final _columnName = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
  static bool _isSafeColumn(String name) => _columnName.hasMatch(name);

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
