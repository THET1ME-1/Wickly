import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../data/media_repository.dart';
import '../data/media_store.dart';
import '../models/media.dart';

/// Распознавание текста на фотографиях.
///
/// Нужно ради поиска: табличка на набережной, страница книги, записка на
/// холодильнике — всё это человек потом ищет словами, а не датой. Работает
/// на самом телефоне, ничего никуда не отправляет.
///
/// Запускается в фоне после того, как фото уже прикреплено: ждать распознавание
/// перед показом карточки незачем.
class OcrService {
  const OcrService._();

  /// Слишком короткие находки — это шум вроде «12» на ценнике: они забивают
  /// поиск и ничего не помогают вспомнить.
  static const _minLength = 4;

  static TextRecognizer? _recognizer;

  static bool get _supported => Platform.isAndroid || Platform.isIOS;

  /// Распознаёт текст и дописывает его во вложение.
  static Future<void> recognize(Media media) async {
    if (!_supported || !media.isVisual || media.ocr != null) return;

    // Распознавать нужно оригинал: на превью мелкий текст уже не читается.
    final path = await MediaStore.instance.materialize(media.file);
    if (path == null) return;

    try {
      final recognizer = _recognizer ??= TextRecognizer();
      final result =
          await recognizer.processImage(InputImage.fromFilePath(path));
      final text = result.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.length < _minLength) return;
      await MediaRepository.instance.update(media.copyWith(ocr: text));
    } catch (_) {
      // Нет модели распознавания, неподдерживаемая платформа, битый файл —
      // фото просто останется без текста.
    }
  }

  /// Проходит по вложениям, у которых текста ещё нет.
  ///
  /// Нужен после подъёма бэкапа и для фото, снятых до включения функции.
  static Future<int> backfill({int limit = 50}) async {
    if (!_supported) return 0;
    final media = await MediaRepository.instance.all();
    var done = 0;
    for (final m in media) {
      if (done >= limit) break;
      if (!m.isVisual || m.ocr != null) continue;
      await recognize(m);
      done++;
    }
    return done;
  }

  /// Отпускает нативный распознаватель.
  static Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
