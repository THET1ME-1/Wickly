import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../l10n/locale_controller.dart';

/// Данные о доступном обновлении с GitHub Releases.
class UpdateInfo {
  final String version; // тег без «v», напр. «0.2.6»
  final String notes; // тело релиза (описание)
  final String? apkUrl; // прямая ссылка на .apk-ассет (или null)
  final String releaseUrl; // страница релиза на GitHub

  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.apkUrl,
    required this.releaseUrl,
  });
}

/// Проверка обновлений по последнему релизу на GitHub и загрузка APK для
/// установки. Приложение раздаётся не через магазин, поэтому обновление ищет
/// себя само — как в Kadr и ScoreMaster.
///
/// Предрелизы пропускаем: `releases/latest` их не отдаёт, и это правильно —
/// непроверенная сборка не должна прилетать сама.
class UpdateService {
  UpdateService._();

  static const String _owner = 'THET1ME-1';
  static const String _repo = 'Wickly';

  static Uri get _latestReleaseUri =>
      Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest');

  /// Возвращает [UpdateInfo], если на GitHub есть релиз новее [currentVersion];
  /// иначе null (в т.ч. при отсутствии сети или ошибке — молча).
  /// null — успешно проверили, НЕ новее (последняя версия). Бросает при ошибке
  /// сети/API (чтобы «не удалось проверить» не выдавалось за «последняя версия»).
  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final request = await client.getUrl(_latestReleaseUri);
      // GitHub API требует User-Agent, иначе 403.
      request.headers.set(HttpHeaders.userAgentHeader, 'Wickly-Updater');
      request.headers
          .set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final response = await request.close();
      // 404 — полных релизов нет, одни предрелизы. Это не сбой: обновляться
      // не на что, и «не удалось проверить» тут соврало бы.
      if (response.statusCode == HttpStatus.notFound) return null;
      if (response.statusCode != 200) {
        throw HttpException('GitHub API ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();

      final json = jsonDecode(body) as Map<String, dynamic>;
      final tag = (json['tag_name'] ?? '').toString();
      final latest = _normalize(tag);
      if (latest.isEmpty) return null;

      if (!_isNewer(latest, _normalize(currentVersion))) return null;

      final assets = json['assets'];
      final apkUrl = assets is List ? _pickApkUrl(assets) : null;

      return UpdateInfo(
        version: latest,
        notes: _localizedNotes(
            (json['body'] ?? '').toString(), LocaleController.instance.code),
        apkUrl: (apkUrl != null && apkUrl.isNotEmpty) ? apkUrl : null,
        releaseUrl: (json['html_url'] ??
                'https://github.com/$_owner/$_repo/releases/latest')
            .toString(),
      );
    } finally {
      client.close();
    }
  }

  /// Скачивает APK по ссылке во временный файл, дёргая [onProgress] (0..1).
  /// Возвращает путь к файлу или null при ошибке.
  static Future<String?> downloadApk(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 20);
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set(HttpHeaders.userAgentHeader, 'Wickly-Updater');
      final response = await request.close(); // редиректы следуются по умолчанию
      if (response.statusCode != 200) {
        client.close();
        return null;
      }

      // Внешняя app-папка надёжнее открывается системным установщиком; если
      // недоступна — временная.
      final dir =
          await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final file = File('${dir.path}/wickly_update.apk');
      if (await file.exists()) await file.delete();
      final sink = file.openWrite();

      final total = response.contentLength; // может быть -1
      var received = 0;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && onProgress != null) {
          onProgress((received / total).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
      await sink.close();
      client.close();
      onProgress?.call(1.0);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// ABI-метка текущего устройства для выбора нужного сплит-APK.
  static String _deviceAbi() {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'arm64-v8a';
    if (abi == Abi.androidArm) return 'armeabi-v7a';
    if (abi == Abi.androidX64) return 'x86_64';
    if (abi == Abi.androidIA32) return 'x86';
    return '';
  }

  static const List<String> _abiTokens = [
    'arm64-v8a',
    'armeabi-v7a',
    'x86_64',
    'x86',
  ];

  /// Выбирает APK-ассет под архитектуру устройства: точное совпадение ABI →
  /// универсальный (без ABI-метки) → первый попавшийся. Работает и со
  /// сплит-релизом (несколько APK), и со старым единым.
  static String? _pickApkUrl(List assets) {
    final abi = _deviceAbi();
    String? abiMatch, universal, firstApk;
    for (final a in assets) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      if (!name.endsWith('.apk')) continue;
      final url = (a['browser_download_url'] ?? '').toString();
      if (url.isEmpty) continue;
      firstApk ??= url;
      if (abi.isNotEmpty && name.contains(abi)) {
        abiMatch ??= url;
      } else if (!_abiTokens.any(name.contains)) {
        universal ??= url;
      }
    }
    return abiMatch ?? universal ?? firstApk;
  }

  /// «0.2.10» > «0.2.2» (числовое сравнение по компонентам).
  static bool _isNewer(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static List<int> _parts(String v) =>
      v.split('.').map((s) => int.tryParse(s.trim()) ?? 0).toList();

  /// Достаёт из двуязычного тела релиза секцию под язык интерфейса. Формат тела:
  /// `<!--lang:ru-->…<!--/lang:ru-->` и `<!--lang:en-->…<!--/lang:en-->`
  /// (HTML-комментарии невидимы на странице GitHub, но есть в теле из API).
  /// Русский → ru-секция; любой другой язык → en-секция (пишем только ru+en).
  /// Если маркеров нет (старые релизы) — возвращает всё тело как есть.
  static String _localizedNotes(String body, String code) {
    String? block(String lang) {
      final re = RegExp(
        '<!--\\s*lang:$lang\\s*-->(.*?)<!--\\s*/\\s*lang:$lang\\s*-->',
        dotAll: true,
        caseSensitive: false,
      );
      return re.firstMatch(body)?.group(1)?.trim();
    }

    final chosen =
        (code == 'ru' ? block('ru') : block('en')) ?? block('en') ?? block('ru');
    final text =
        (chosen != null && chosen.isNotEmpty) ? chosen : body.trim();
    return _stripMarkdown(text);
  }

  /// Лёгкая чистка markdown, чтобы попап обновления не показывал `#`, `**`, `` ` ``
  /// как символы (тело показывается обычным текстом, без рендера markdown).
  static String _stripMarkdown(String s) {
    final lines = s.split('\n').map((line) {
      var l = line;
      l = l.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*'), ''); // заголовки
      l = l.replaceAll(RegExp(r'^\s*[-*]\s+'), '• '); // маркеры списка
      l = l.replaceAllMapped(
          RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1)!); // **жирный**
      l = l.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!); // `код`
      if (RegExp(r'^\s*---+\s*$').hasMatch(l)) l = ''; // разделители
      return l;
    }).toList();
    // Схлопываем повторяющиеся пустые строки.
    final out = <String>[];
    for (final l in lines) {
      if (l.trim().isEmpty && out.isNotEmpty && out.last.trim().isEmpty) {
        continue;
      }
      out.add(l);
    }
    return out.join('\n').trim();
  }

  /// Убираем ведущую «v»: «v0.2.6» → «0.2.6».
  static String _normalize(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    // отсекаем build-суффикс, если пришёл «0.2.6+7»
    final plus = s.indexOf('+');
    if (plus != -1) s = s.substring(0, plus);
    return s;
  }
}
