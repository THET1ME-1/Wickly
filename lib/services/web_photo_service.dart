import 'dart:convert';

import 'package:http/http.dart' as http;

/// Фотография из сети вместе с тем, кого за неё благодарить.
class WebPhoto {
  final String id;
  final String thumbUrl;
  final String fullUrl;
  final String author;
  final String license;

  /// Страница снимка у источника — по правилам лицензий на неё надо ссылаться.
  final String pageUrl;

  const WebPhoto({
    required this.id,
    required this.thumbUrl,
    required this.fullUrl,
    required this.author,
    required this.license,
    required this.pageUrl,
  });

  /// «Фото: Имя Автора · CC BY» — подпись под обложкой.
  String get credit {
    final parts = [
      if (author.isNotEmpty) author,
      if (license.isNotEmpty) license.toUpperCase(),
    ];
    return parts.join(' · ');
  }
}

/// Подбор обложки по теме записи.
///
/// Источник — Openverse: каталог снимков под свободными лицензиями, который
/// отдаёт имя автора и лицензию прямо в ответе и **не требует ключа**. Именно
/// поэтому не Unsplash: их API работает только с ключом приложения, а класть
/// ключ в открытый репозиторий нельзя — он утечёт в первый же день, и это
/// нарушение их правил.
///
/// Снимок скачивается и ложится в дневник рядом с остальными вложениями:
/// обложка должна открываться в самолёте, а не только при сети.
class WebPhotoService {
  const WebPhotoService._();

  static const _endpoint = 'https://api.openverse.org/v1/images/';

  /// Ищет снимки по теме. Пустой запрос вернёт пустой список, а не случайное.
  static Future<List<WebPhoto>> search(String topic, {int limit = 12}) async {
    final query = topic.trim();
    if (query.isEmpty) return const [];

    try {
      final uri = Uri.parse(_endpoint).replace(queryParameters: {
        'q': query,
        'page_size': '$limit',
        // Только то, что можно показывать без оговорок и переиспользовать.
        'license_type': 'all-cc',
        'mature': 'false',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'Wickly/1.0 (личный дневник)'},
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const [];

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
      final results = json['results'];
      if (results is! List) return const [];

      return [
        for (final raw in results)
          if (raw is Map<String, Object?>) ?_photo(raw),
      ];
    } catch (_) {
      // Нет сети или источник молчит — обложку человек выберет сам.
      return const [];
    }
  }

  static WebPhoto? _photo(Map<String, Object?> raw) {
    final full = (raw['url'] ?? '').toString();
    if (full.isEmpty) return null;
    return WebPhoto(
      id: (raw['id'] ?? full).toString(),
      thumbUrl: (raw['thumbnail'] ?? full).toString(),
      fullUrl: full,
      author: (raw['creator'] ?? '').toString(),
      license: (raw['license'] ?? '').toString(),
      pageUrl: (raw['foreign_landing_url'] ?? '').toString(),
    );
  }

  /// Скачивает выбранный снимок.
  static Future<List<int>?> download(WebPhoto photo) async {
    try {
      final response = await http.get(Uri.parse(photo.fullUrl)).timeout(
            const Duration(seconds: 25),
          );
      if (response.statusCode != 200) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }
}
