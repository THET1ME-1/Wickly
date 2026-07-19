import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/catalog_repository.dart';
import '../data/crypto.dart';
import '../data/journal_repository.dart';
import '../data/media_repository.dart';
import '../data/media_store.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import '../models/media.dart';
import '../utils/dates.dart';
import '../widgets/markdown_lite.dart';

/// Выгрузка дневника наружу и подъём его обратно.
///
/// Дневник не должен запирать человека внутри себя: всё, что он написал,
/// выгружается в форматы, которые откроются и без Wickly — Markdown, JSON,
/// обычный текст и PDF-книга. Бэкап отдельно: он шифрованный и годится для
/// переезда на новый телефон.
class ExportService {
  const ExportService._();

  /// Markdown: одна запись — один заголовок с датой и метаданными.
  static String toMarkdown(List<Entry> entries) {
    final out = StringBuffer();
    for (final e in entries) {
      out.writeln('## ${_title(e)}');
      out.writeln();
      out.writeln('*${Dates.full(e.entryDate)}, ${Dates.time(e.entryDate)}*');
      final meta = [
        if (e.place != null) e.place!,
        if (e.weather != null) e.weather!,
        if (e.mood != null) '${tr('set_mood')}: ${e.mood}/5',
      ];
      if (meta.isNotEmpty) out.writeln('*${meta.join(' · ')}*');
      out.writeln();
      if ((e.body ?? '').trim().isNotEmpty) {
        out.writeln(e.body!.trim());
        out.writeln();
      }
      out.writeln('---');
      out.writeln();
    }
    return out.toString();
  }

  /// Обычный текст — для тех, кому нужен голый дневник без разметки.
  static String toPlainText(List<Entry> entries) {
    final out = StringBuffer();
    for (final e in entries) {
      out.writeln('${Dates.full(e.entryDate)}, ${Dates.time(e.entryDate)}');
      out.writeln(_title(e));
      out.writeln();
      final body = MarkdownLite.strip(e.body);
      if (body.isNotEmpty) {
        out.writeln(body);
        out.writeln();
      }
      out.writeln('${'-' * 40}\n');
    }
    return out.toString();
  }

  /// JSON — полная копия со всеми полями, из неё можно собрать дневник заново.
  static Future<String> toJson(List<Entry> entries) async {
    final media = await MediaRepository.instance.all();
    final byEntry = <String, List<Media>>{};
    for (final m in media) {
      (byEntry[m.entryId] ??= []).add(m);
    }
    final tagLinks =
        await CatalogRepository.instance.allLinks('entry_tags', 'tag_id');
    final tags = {
      for (final t in await CatalogRepository.instance.tags()) t.id: t.name,
    };
    final journals = {
      for (final j in await JournalRepository.instance.all()) j.id: j.name,
    };

    return const JsonEncoder.withIndent('  ').convert({
      'app': 'Wickly',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'entries': [
        for (final e in entries)
          {
            'id': e.id,
            'journal': journals[e.journalId] ?? e.journalId,
            'date': e.entryDate.toIso8601String(),
            'created': e.createdAt.toIso8601String(),
            'title': e.title,
            'body': e.body,
            'mood': e.mood,
            'weather': e.weather,
            'temperature': e.temp,
            'place': e.place,
            'lat': e.lat,
            'lon': e.lon,
            'favorite': e.favorite,
            'wordCount': e.wordCount,
            'tags': [
              for (final id in tagLinks[e.id] ?? const <String>[])
                if (tags[id] != null) tags[id],
            ],
            'media': [
              for (final m in byEntry[e.id] ?? const <Media>[])
                {'kind': m.kind.name, 'file': m.file, 'caption': m.caption},
            ],
          },
      ],
    });
  }

  /// «Книга» в PDF: обложка, а дальше записи с фотографиями.
  ///
  /// Фотографии ужимаются перед вставкой: иначе год с телефона превращается в
  /// файл на сотни мегабайт, который не открывается и не отправляется.
  static Future<Uint8List> toPdfBook(
    List<Entry> entries, {
    required String title,
    bool withPhotos = true,
    int maxPhotosPerEntry = 3,
  }) async {
    final doc = pw.Document();
    final display = pw.Font.ttf(await rootBundle.load('assets/fonts/Unbounded.ttf'));
    final body = pw.Font.ttf(await rootBundle.load('assets/fonts/Onest.ttf'));

    final theme = pw.ThemeData.withFont(base: body, bold: body);
    final photos = <String, List<pw.MemoryImage>>{};

    if (withPhotos) {
      final media = await MediaRepository.instance.all();
      for (final m in media) {
        if (!m.isVisual) continue;
        final list = photos[m.entryId] ??= [];
        if (list.length >= maxPhotosPerEntry) continue;
        final bytes = await MediaStore.instance.read(m.thumb ?? m.file);
        if (bytes != null) list.add(pw.MemoryImage(bytes));
      }
    }

    final years = entries.map((e) => e.entryDate.year).toSet().toList()..sort();

    doc.addPage(
      pw.Page(
        theme: theme,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(font: display, fontSize: 34)),
              pw.SizedBox(height: 12),
              pw.Text(
                years.isEmpty
                    ? ''
                    : (years.length == 1
                        ? '${years.first}'
                        : '${years.first} — ${years.last}'),
                style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                Dates.entryCount(entries.length),
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(48, 54, 48, 54),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ),
        build: (context) => [
          for (final e in entries) ..._pdfEntry(e, display, photos[e.id]),
        ],
      ),
    );

    return doc.save();
  }

  static List<pw.Widget> _pdfEntry(
    Entry e,
    pw.Font display,
    List<pw.MemoryImage>? images,
  ) {
    final meta = [
      '${Dates.full(e.entryDate)}, ${Dates.time(e.entryDate)}',
      if (e.place != null) e.place!,
      if (e.weather != null) e.weather!,
    ].join(' · ');

    return [
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 4),
        child: pw.Text(_title(e),
            style: pw.TextStyle(font: display, fontSize: 15)),
      ),
      pw.Text(meta,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
      pw.SizedBox(height: 8),
      if (MarkdownLite.strip(e.body).isNotEmpty)
        pw.Text(
          MarkdownLite.strip(e.body),
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
          textAlign: pw.TextAlign.left,
        ),
      if (images != null && images.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final image in images)
              pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(image, width: 150, height: 110,
                    fit: pw.BoxFit.cover),
              ),
          ],
        ),
      ],
      pw.SizedBox(height: 14),
      pw.Divider(color: PdfColors.grey300, height: 1),
    ];
  }

  /// Пишет файл во временный каталог и отдаёт путь — дальше «поделиться».
  static Future<File> writeTemp(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _title(Entry e) {
    final t = e.title?.trim();
    if (t != null && t.isNotEmpty) return t;
    final body = MarkdownLite.strip(e.body);
    if (body.isEmpty) return tr('entry_untitled');
    return body.length <= 50 ? body : '${body.substring(0, 50)}…';
  }
}

/// Полный бэкап: база, вложения и опись — одним зашифрованным файлом.
///
/// Шифруется парольной фразой, а не ключом устройства: бэкап должен
/// открываться на новом телефоне, где старого ключа уже нет.
class BackupService {
  const BackupService._();

  static const fileExtension = 'wickly';
  static const _manifest = 'manifest.json';
  static const _dbName = 'wickly.db';

  /// Метка формата v2 («WBK2») в начале файла. За ней — случайная соль, потом
  /// шифртекст. Старые бэкапы метки не имеют (шли сразу с шифртекста при общей
  /// для всех соли), поэтому по её наличию и различаем формат при восстановлении.
  static const _magicV2 = [0x57, 0x42, 0x4B, 0x32];
  static const _saltLen = 16;

  /// Соль старого формата — одна на всех. Оставлена только чтобы открывать
  /// бэкапы, сделанные до перехода на случайную соль.
  static final List<int> _legacySalt = utf8.encode('wickly-backup-v1');

  /// Собирает бэкап. [dbPath] — путь к файлу базы, [passphrase] — фраза,
  /// которой его потом открывать.
  static Future<Uint8List> create({
    required String dbPath,
    required String passphrase,
  }) async {
    final archive = Archive();

    final db = File(dbPath);
    if (db.existsSync()) {
      final bytes = await db.readAsBytes();
      archive.addFile(ArchiveFile(_dbName, bytes.length, bytes));
    }

    // Вложения кладём как есть — они уже зашифрованы ключом устройства,
    // но ключ уедет вместе с бэкапом в описи, иначе на новом телефоне их
    // нечем будет открыть.
    for (final name in await MediaStore.instance.listNames()) {
      final bytes = await MediaStore.instance.readRaw(name);
      if (bytes != null) {
        archive.addFile(ArchiveFile('media/$name', bytes.length, bytes));
      }
    }

    final manifest = jsonEncode({
      'app': 'Wickly',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'mediaKey': Crypto.instance.keyHex,
    });
    final manifestBytes = utf8.encode(manifest);
    archive.addFile(
        ArchiveFile(_manifest, manifestBytes.length, manifestBytes));

    final zipped = ZipEncoder().encode(archive);
    // Соль случайна на каждый бэкап и едет в файле: без этого одну таблицу
    // «фраза → ключ» можно было предвычислить на всех пользователей сразу.
    final rnd = Random.secure();
    final salt = List<int>.generate(_saltLen, (_) => rnd.nextInt(256));
    final key = await Crypto.keyFromPassphrase(passphrase, salt);
    final body = await Crypto.instance.encryptBytesWith(zipped, key);
    return Uint8List.fromList([..._magicV2, ...salt, ...body]);
  }

  /// Раскрывает бэкап: кладёт базу и вложения на место.
  ///
  /// Возвращает ключ шифрования вложений из описи — вызывающий код должен
  /// сохранить его в системное хранилище, иначе фотографии останутся шумом.
  static Future<String?> restore({
    required Uint8List sealed,
    required String passphrase,
    required String dbPath,
  }) async {
    // v2 — «WBK2» ‖ соль ‖ шифртекст; старый формат — сразу шифртекст с общей
    // солью. По метке в начале и решаем, как выводить ключ.
    final List<int> salt;
    final List<int> body;
    if (sealed.length > _magicV2.length + _saltLen &&
        _startsWith(sealed, _magicV2)) {
      salt = sealed.sublist(_magicV2.length, _magicV2.length + _saltLen);
      body = sealed.sublist(_magicV2.length + _saltLen);
    } else {
      salt = _legacySalt;
      body = sealed;
    }
    final key = await Crypto.keyFromPassphrase(passphrase, salt);
    final zipped = await Crypto.instance.decryptBytesWith(body, key);
    final archive = ZipDecoder().decodeBytes(zipped);
    return _restoreArchive(archive, dbPath);
  }

  static bool _startsWith(List<int> data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }

  static Future<String?> _restoreArchive(Archive archive, String dbPath) async {

    String? mediaKey;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final bytes = file.content as List<int>;
      if (file.name == _manifest) {
        final json = (jsonDecode(utf8.decode(bytes)) as Map)
            .cast<String, Object?>();
        mediaKey = json['mediaKey'] as String?;
      } else if (file.name == _dbName) {
        await File(dbPath).writeAsBytes(bytes, flush: true);
      } else if (file.name.startsWith('media/')) {
        await MediaStore.instance
            .writeRaw(file.name.substring('media/'.length), bytes);
      }
    }
    return mediaKey;
  }
}
