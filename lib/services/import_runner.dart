import 'dart:typed_data';

import '../data/catalog_repository.dart';
import '../data/entry_repository.dart';
import '../data/journal_repository.dart';
import '../data/media_repository.dart';
import '../data/media_store.dart';
import '../models/entry.dart';
import '../models/media.dart';
import 'import_service.dart';

/// Сколько всего перенесено.
class ImportReport {
  final int journals;
  final int entries;
  final int media;

  const ImportReport({
    this.journals = 0,
    this.entries = 0,
    this.media = 0,
  });
}

/// Кладёт разобранный [ImportBundle] в базу Wickly: дневники, записи, теги,
/// вложения. Байты вложений отдаёт [mediaBytes] — так писатель не знает, лежат
/// они в zip-архиве или в папке рядом с JSON.
class ImportRunner {
  const ImportRunner._();

  static Future<ImportReport> run(
    ImportBundle bundle, {
    Future<List<int>?> Function(String sourceName)? mediaBytes,
    void Function(int done, int total)? onProgress,
  }) async {
    var journals = 0, entries = 0, media = 0;
    final total = bundle.entryCount;
    var done = 0;

    // Тег по нормализованному имени: `ensureTag` перебирает все теги, звать его
    // на каждую запись — квадрат. Заводим каждый тег один раз.
    final tagIds = <String, String>{};

    for (final ij in bundle.journals) {
      final journal = Journal.create(
        name: ij.name.isEmpty ? bundle.source : ij.name,
        color: ij.color,
        icon: 'book',
        cover: 'amber',
      );
      await JournalRepository.instance.insert(journal);
      journals++;

      for (final ie in ij.entries) {
        // Пустые записи чужого дневника не тащим — только замусорят ленту.
        if (ie.isEmpty) {
          onProgress?.call(++done, total);
          continue;
        }

        final entry = Entry.create(
          journalId: journal.id,
          title: ie.title,
          body: ie.body,
          entryDate: ie.date,
          mood: ie.mood,
        ).copyWith(
          favorite: ie.favorite,
          pinned: ie.pinned,
          place: ie.place,
          lat: ie.lat,
          lon: ie.lon,
          weather: ie.weather,
          temp: ie.temp,
        );
        await EntryRepository.instance.insert(entry);
        entries++;

        if (ie.tags.isNotEmpty) {
          final ids = <String>[];
          for (final name in ie.tags) {
            final key = name.toLowerCase();
            var id = tagIds[key];
            if (id == null) {
              id = (await CatalogRepository.instance.ensureTag(name)).id;
              tagIds[key] = id;
            }
            ids.add(id);
          }
          await CatalogRepository.instance.setTagsOf(entry.id, ids);
        }

        if (mediaBytes != null && ie.media.isNotEmpty) {
          media += await _attach(entry.id, ie.media, mediaBytes);
        }

        onProgress?.call(++done, total);
      }
    }

    return ImportReport(journals: journals, entries: entries, media: media);
  }

  static Future<int> _attach(
    String entryId,
    List<ImportedMedia> items,
    Future<List<int>?> Function(String) mediaBytes,
  ) async {
    var count = 0;
    var sort = 0;
    for (final im in items) {
      if (im.sourceName.isEmpty) continue;
      List<int>? bytes;
      try {
        bytes = await mediaBytes(im.sourceName);
      } catch (_) {
        bytes = null;
      }
      if (bytes == null || bytes.isEmpty) continue;

      final name = await MediaStore.instance
          .put(Uint8List.fromList(bytes), ext: _extOf(im.sourceName));
      await MediaRepository.instance.insert(Media.create(
        entryId: entryId,
        kind: _kind(im.kind),
        file: name,
        sort: sort++,
      ));
      count++;
    }
    return count;
  }

  static MediaKind _kind(ImportMediaKind k) => switch (k) {
        ImportMediaKind.video => MediaKind.video,
        ImportMediaKind.audio => MediaKind.audio,
        ImportMediaKind.photo => MediaKind.photo,
      };

  static String _extOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return 'jpg';
    final ext = name.substring(dot + 1).toLowerCase();
    return RegExp(r'^[a-z0-9]{1,5}$').hasMatch(ext) ? ext : 'jpg';
  }
}
