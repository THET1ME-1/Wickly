import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Шифрование содержимого записей на уровне приложения — **AES-256-GCM**
/// (аутентифицированное шифрование). Чистый Dart: работает на всех платформах и
/// проверяется на хосте.
///
/// Ключ приходит извне (из системного хранилища — см. `DbKey`); сам крипто-слой
/// не знает, откуда он, поэтому не тянет плагины и остаётся тестируемым.
class Crypto {
  Crypto._();
  static final Crypto instance = Crypto._();

  final _algo = AesGcm.with256bits();
  SecretKey? _key;

  bool get isReady => _key != null;

  /// [keyHex] — 64 hex-символа = 32-байтный ключ.
  void init(String keyHex) {
    _key = SecretKey(_hexToBytes(keyHex));
  }

  /// Шифрует карту полей → компактная base64-строка (nonce ‖ ciphertext ‖ mac).
  Future<String> encryptJson(Map<String, Object?> data) async {
    final clear = utf8.encode(jsonEncode(data));
    final box = await _algo.encrypt(clear, secretKey: _key!);
    return base64Encode([...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  /// Расшифровывает строку из [encryptJson] обратно в карту полей.
  Future<Map<String, Object?>> decryptJson(String enc) async {
    final raw = base64Decode(enc);
    final nonce = raw.sublist(0, 12);
    final mac = Mac(raw.sublist(raw.length - 16));
    final cipher = raw.sublist(12, raw.length - 16);
    final clear =
        await _algo.decrypt(SecretBox(cipher, nonce: nonce, mac: mac), secretKey: _key!);
    return (jsonDecode(utf8.decode(clear)) as Map).cast<String, Object?>();
  }

  /// Шифрует произвольные байты (файлы вложений и бэкапы).
  /// Формат тот же: nonce ‖ ciphertext ‖ mac — одним блобом.
  Future<Uint8List> encryptBytes(List<int> bytes) async {
    final box = await _algo.encrypt(bytes, secretKey: _key!);
    return Uint8List.fromList(
        [...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  Future<Uint8List> decryptBytes(List<int> raw) async {
    final nonce = raw.sublist(0, 12);
    final mac = Mac(raw.sublist(raw.length - 16));
    final cipher = raw.sublist(12, raw.length - 16);
    final clear = await _algo.decrypt(
      SecretBox(cipher, nonce: nonce, mac: mac),
      secretKey: _key!,
    );
    return Uint8List.fromList(clear);
  }

  /// Шифрование произвольным ключом — для бэкапов с парольной фразой,
  /// которые должны открываться на другом устройстве.
  Future<Uint8List> encryptBytesWith(List<int> bytes, SecretKey key) async {
    final box = await _algo.encrypt(bytes, secretKey: key);
    return Uint8List.fromList(
        [...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  Future<Uint8List> decryptBytesWith(List<int> raw, SecretKey key) async {
    final nonce = raw.sublist(0, 12);
    final mac = Mac(raw.sublist(raw.length - 16));
    final cipher = raw.sublist(12, raw.length - 16);
    final clear = await _algo.decrypt(
      SecretBox(cipher, nonce: nonce, mac: mac),
      secretKey: key,
    );
    return Uint8List.fromList(clear);
  }

  /// Ключ из парольной фразы (PBKDF2-HMAC-SHA256) — для шифрованного бэкапа.
  static Future<SecretKey> keyFromPassphrase(
    String passphrase,
    List<int> salt,
  ) async {
    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000,
      bits: 256,
    );
    return kdf.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  static List<int> _hexToBytes(String hex) => [
        for (var i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ];
}
