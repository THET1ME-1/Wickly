import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Сколько поисков обложки осталось. Openverse считает анонимные запросы
/// **по адресу**, а не по приложению: бюджет свой у каждого, кто ищет, и
/// делится только с теми, кто сидит за тем же роутером.
class WebPhotoQuota {
  /// Осталось в этой минуте и за сегодня; -1 — сервер не сказал.
  final int leftThisMinute;
  final int leftToday;

  /// Потолки, чтобы показать «7 из 200», а не голое число.
  final int perMinute;
  final int perDay;

  /// Openverse ответил 429: искать сейчас нельзя.
  final bool exhausted;

  const WebPhotoQuota({
    this.leftThisMinute = -1,
    this.leftToday = -1,
    this.perMinute = -1,
    this.perDay = -1,
    this.exhausted = false,
  });

  /// Есть что показывать человеку.
  bool get known => leftToday >= 0 || leftThisMinute >= 0 || exhausted;

  /// Осталась пятая часть дневного бюджета или меньше — пора предупредить.
  bool get low =>
      exhausted || (leftToday >= 0 && perDay > 0 && leftToday <= perDay ~/ 5);
}

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

  /// Openverse просит представляться. Только ASCII: не-ASCII в значении
  /// заголовка Dart роняет `FormatException` ещё до отправки запроса, а
  /// `catch` ниже глотает её — поиск молча возвращал бы пустоту всегда.
  static const userAgent = 'Wickly/1.0 (personal journal)';

  /// Анонимному запросу Openverse отдаёт максимум 20 снимков за раз; больше —
  /// не ошибка полей, а 401.
  static const maxPageSize = 20;

  /// Остаток лимита из последнего ответа. Пусто, пока не искали ни разу.
  static final ValueNotifier<WebPhotoQuota> quota =
      ValueNotifier(const WebPhotoQuota());

  /// Ищет снимки по теме. Пустой запрос вернёт пустой список, а не случайное.
  static Future<List<WebPhoto>> search(String topic, {int limit = 12}) async {
    final query = topic.trim();
    if (query.isEmpty) return const [];

    try {
      final uri = Uri.parse(_endpoint).replace(queryParameters: {
        'q': query,
        'page_size': '${limit.clamp(1, maxPageSize)}',
        // Только то, что можно показывать без оговорок и переиспользовать.
        'license_type': 'all-cc',
        'mature': 'false',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': userAgent},
      ).timeout(const Duration(seconds: 12));
      quota.value = _quotaFrom(response.headers, response.statusCode);
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

  /// Разбирает заголовки вида `x-ratelimit-available-anon_sustained: 199` и
  /// `x-ratelimit-limit-anon_sustained: 200/day`.
  @visibleForTesting
  static WebPhotoQuota quotaFrom(Map<String, String> headers, int status) =>
      _quotaFrom(headers, status);

  static WebPhotoQuota _quotaFrom(Map<String, String> headers, int status) {
    int number(String key) {
      final raw = headers[key];
      if (raw == null) return -1;
      // У потолка после числа висит период («200/day») — берём число.
      final digits = RegExp(r'\d+').firstMatch(raw)?.group(0);
      return digits == null ? -1 : int.parse(digits);
    }

    return WebPhotoQuota(
      leftThisMinute: number('x-ratelimit-available-anon_burst'),
      leftToday: number('x-ratelimit-available-anon_sustained'),
      perMinute: number('x-ratelimit-limit-anon_burst'),
      perDay: number('x-ratelimit-limit-anon_sustained'),
      exhausted: status == 429,
    );
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
