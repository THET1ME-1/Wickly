import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Ключ шифрования базы. Хранится в системном защищённом хранилище —
/// Android Keystore / iOS Keychain (через flutter_secure_storage), а не в
/// обычных prefs. Генерируется один раз, случайно (32 байта).
class DbKey {
  DbKey._();

  static const _storage = FlutterSecureStorage();
  static const _k = 'wickly_db_key';

  /// Возвращает существующий ключ или создаёт новый (64 hex-символа).
  static Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _k);
    if (existing != null && existing.length == 64) return existing;
    final rnd = Random.secure();
    final hex = List<int>.generate(32, (_) => rnd.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    await _storage.write(key: _k, value: hex);
    return hex;
  }

  /// Ставит ключ из поднятого бэкапа.
  ///
  /// Без этого база встанет на место, а вложения останутся нечитаемым шумом:
  /// они зашифрованы ключом того устройства, где были сняты.
  static Future<void> replace(String keyHex) async {
    if (keyHex.length != 64) return;
    await _storage.write(key: _k, value: keyHex);
  }
}
