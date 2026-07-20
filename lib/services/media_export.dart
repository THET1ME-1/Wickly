import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import '../data/media_store.dart';
import '../data/system_pause.dart';
import '../models/media.dart';

/// Чем кончилась попытка забрать вложение из дневника наружу.
enum SaveResult {
  /// Файл лёг в галерею или туда, куда указал человек.
  saved,

  /// Человек закрыл системный диалог выбора папки.
  cancelled,

  /// Android или iOS не дали доступа к галерее.
  denied,

  /// Файла нет, ключ не подошёл, диск не пустил.
  failed,
}

/// Отдаёт вложение обратно устройству: в галерею или через «Поделиться».
///
/// Дневник хранит фото **зашифрованной копией** внутри себя и на исходник из
/// галереи не опирается — оригинал можно удалить сразу после того, как снимок
/// прикреплён. Обратная дорога до сих пор существовала только через полный
/// экспорт всего дневника, поэтому вынуть одно фото было нечем.
///
/// Сохранённый файл выходит из-под шифрования и замка: дальше он живёт по
/// правилам галереи, а не дневника.
class MediaExport {
  const MediaExport._();

  /// Кладёт вложение в галерею устройства (на десктопе — в выбранную папку).
  static Future<SaveResult> saveToDevice(Media media) async {
    final path = await MediaStore.instance.materialize(media.file);
    if (path == null) return SaveResult.failed;

    // Системный выбор папки и запрос доступа к галерее уводят приложение в
    // фон. Без щита дневник запирается, и на возврате человек видит замок
    // вместо своего фото.
    return SystemPause.shield(() async {
      try {
        if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
          if (!await Gal.hasAccess(toAlbum: true) &&
              !await Gal.requestAccess(toAlbum: true)) {
            return SaveResult.denied;
          }
          // Альбом «Wickly»: иначе снимки из дневника растворяются в общей
          // ленте камеры вперемешку со всем остальным.
          if (media.kind == MediaKind.video) {
            await Gal.putVideo(path, album: _album);
          } else {
            await Gal.putImage(path, album: _album);
          }
          return SaveResult.saved;
        }

        // Десктоп: галереи нет — спрашиваем, куда положить.
        final target = await FilePicker.saveFile(
          fileName: media.file,
          bytes: await File(path).readAsBytes(),
        );
        if (target == null) return SaveResult.cancelled;
        // Linux и Windows возвращают путь, но файл не пишут — делаем сами.
        // На macOS `saveFile` с байтами записывает файл и сама.
        final out = File(target);
        if (!out.existsSync() || out.lengthSync() == 0) {
          await out.writeAsBytes(await File(path).readAsBytes());
        }
        return SaveResult.saved;
      } on GalException catch (e) {
        return e.type == GalExceptionType.accessDenied
            ? SaveResult.denied
            : SaveResult.failed;
      } catch (_) {
        return SaveResult.failed;
      }
    });
  }

  /// Отдаёт вложение системному «Поделиться».
  static Future<bool> share(Media media) async {
    final path = await MediaStore.instance.materialize(media.file);
    if (path == null) return false;
    return SystemPause.shield(() async {
      try {
        await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  static const _album = 'Wickly';
}
