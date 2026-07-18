import 'crypto.dart';

/// Кэш расшифровки, чтобы лента и статистика не дешифровали одно и то же по
/// сто раз на каждый тик базы.
///
/// Ключ — **сам шифртекст**: любое изменение строки рождает новый `enc` (у
/// AES-GCM свой nonce на каждое шифрование), поэтому кэш инвалидируется сам и
/// не может отдать протухшие данные.
class EncCache {
  const EncCache._();

  static const _limit = 2000;
  static final _map = <String, Map<String, Object?>>{};

  static const _empty = <String, Object?>{};

  static Future<Map<String, Object?>> decode(String? enc) async {
    if (enc == null || enc.isEmpty) return _empty;
    final hit = _map[enc];
    if (hit != null) return hit;
    final Map<String, Object?> payload;
    try {
      payload = await Crypto.instance.decryptJson(enc);
    } catch (_) {
      // Чужой ключ или битая строка — не роняем экран, показываем пустое.
      return _empty;
    }
    if (_map.length >= _limit) {
      // Простое усечение: кэш — ускорение, а не источник истины.
      _map.remove(_map.keys.first);
    }
    _map[enc] = payload;
    return payload;
  }

  /// Полная очистка — при смене ключа или выходе из защищённого раздела.
  static void clear() => _map.clear();
}
