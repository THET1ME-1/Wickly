import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Вид вложения записи.
enum MediaKind {
  photo,
  video,
  audio,

  /// Рисунок от руки (скетч) — хранится как PNG.
  sketch;

  static MediaKind parse(String? s) => MediaKind.values.firstWhere(
        (k) => k.name == s,
        orElse: () => MediaKind.photo,
      );
}

/// Вложение записи: фото, видео, аудио-заметка или скетч.
///
/// Сам файл лежит на диске **зашифрованным** (см. `MediaStore`), в базе — только
/// имя файла, вид и порядок. Подпись, EXIF (где и когда снято) и распознанный
/// текст фотографии живут в зашифрованном `enc`.
class Media {
  final String id;
  final String entryId;
  final MediaKind kind;

  /// Имя зашифрованного файла в каталоге медиа (без пути).
  final String file;

  /// Имя зашифрованного превью (для фото и видео).
  final String? thumb;

  final int sort;
  final DateTime createdAt;

  final String? caption;

  /// EXIF: когда и где снято.
  final DateTime? takenAt;
  final double? lat;
  final double? lon;
  final String? place;

  /// Длительность аудио/видео в миллисекундах.
  final int? durationMs;

  final int? width;
  final int? height;

  /// Текст, распознанный на фотографии — по нему ищет полнотекстовый поиск.
  final String? ocr;

  const Media({
    required this.id,
    required this.entryId,
    required this.kind,
    required this.file,
    this.thumb,
    this.sort = 0,
    required this.createdAt,
    this.caption,
    this.takenAt,
    this.lat,
    this.lon,
    this.place,
    this.durationMs,
    this.width,
    this.height,
    this.ocr,
  });

  factory Media.create({
    required String entryId,
    required MediaKind kind,
    required String file,
    String? thumb,
    int sort = 0,
    String? caption,
    DateTime? takenAt,
    double? lat,
    double? lon,
    String? place,
    int? durationMs,
    int? width,
    int? height,
    String? ocr,
  }) =>
      Media(
        id: _uuid.v4(),
        entryId: entryId,
        kind: kind,
        file: file,
        thumb: thumb,
        sort: sort,
        createdAt: DateTime.now(),
        caption: caption,
        takenAt: takenAt,
        lat: lat,
        lon: lon,
        place: place,
        durationMs: durationMs,
        width: width,
        height: height,
        ocr: ocr,
      );

  bool get isVisual => kind == MediaKind.photo || kind == MediaKind.sketch;

  Map<String, Object?> toRowColumns() => {
        'id': id,
        'entry_id': entryId,
        'kind': kind.name,
        'file': file,
        'thumb': thumb,
        'sort': sort,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  Map<String, Object?> toPayload() => {
        'caption': caption,
        'takenAt': takenAt?.millisecondsSinceEpoch,
        'lat': lat,
        'lon': lon,
        'place': place,
        'durationMs': durationMs,
        'width': width,
        'height': height,
        'ocr': ocr,
      };

  factory Media.fromStorage(
    Map<String, Object?> row,
    Map<String, Object?> payload,
  ) {
    final taken = payload['takenAt'] as int?;
    return Media(
      id: row['id'] as String,
      entryId: row['entry_id'] as String,
      kind: MediaKind.parse(row['kind'] as String?),
      file: row['file'] as String,
      thumb: row['thumb'] as String?,
      sort: (row['sort'] as int?) ?? 0,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch((row['created_at'] as int?) ?? 0),
      caption: payload['caption'] as String?,
      takenAt: taken == null ? null : DateTime.fromMillisecondsSinceEpoch(taken),
      lat: (payload['lat'] as num?)?.toDouble(),
      lon: (payload['lon'] as num?)?.toDouble(),
      place: payload['place'] as String?,
      durationMs: payload['durationMs'] as int?,
      width: payload['width'] as int?,
      height: payload['height'] as int?,
      ocr: payload['ocr'] as String?,
    );
  }

  Media copyWith({
    String? caption,
    int? sort,
    String? ocr,
    String? thumb,
    int? durationMs,
  }) =>
      Media(
        id: id,
        entryId: entryId,
        kind: kind,
        file: file,
        thumb: thumb ?? this.thumb,
        sort: sort ?? this.sort,
        createdAt: createdAt,
        caption: caption ?? this.caption,
        takenAt: takenAt,
        lat: lat,
        lon: lon,
        place: place,
        durationMs: durationMs ?? this.durationMs,
        width: width,
        height: height,
        ocr: ocr ?? this.ocr,
      );
}
