import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

import 'sync_service.dart';

/// Приглашение к сопряжению: что зашито в QR.
class PairInvite {
  final String host;
  final int port;
  final String phrase;

  const PairInvite({
    required this.host,
    required this.port,
    required this.phrase,
  });

  String encode() => jsonEncode({'h': host, 'p': port, 'w': phrase});

  static PairInvite? decode(String raw) {
    try {
      final json = (jsonDecode(raw) as Map).cast<String, Object?>();
      final host = json['h'] as String?;
      final port = (json['p'] as num?)?.toInt();
      final phrase = json['w'] as String?;
      if (host == null || port == null || phrase == null) return null;
      return PairInvite(host: host, port: port, phrase: phrase);
    } catch (_) {
      return null;
    }
  }
}

/// Прямой обмен между устройствами по локальной сети.
///
/// Одно устройство поднимает сокет и показывает QR, второе подключается и они
/// обмениваются пакетами изменений. Сервера посередине нет: данные идут по
/// домашней сети и зашифрованы фразой сопряжения, поэтому даже перехваченный
/// трафик остаётся шумом.
///
/// Обмен всегда двусторонний: каждая сторона шлёт своё и применяет чужое.
/// Кто первый подключился — не важно, слияние CRDT от порядка не зависит.
///
/// Важно: обе роли работают с **одной** базой процесса. Поднять приём и
/// подключиться к самому себе из одного приложения нельзя — это два разных
/// устройства по замыслу.
class P2pService {
  const P2pService._();

  /// Порт по умолчанию. Если занят, сервер возьмёт любой свободный и напишет
  /// его в приглашение.
  static const defaultPort = 47820;

  /// Сколько ждём вторую сторону: дольше человек всё равно не держит экран.
  static const handshakeTimeout = Duration(seconds: 30);

  /// Поднимает приём на этом устройстве.
  static Future<P2pHost> host({
    required String phrase,
    int port = defaultPort,
  }) async {
    ServerSocket server;
    try {
      server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    } on SocketException {
      // Порт занят другим приложением или прошлым запуском — берём любой.
      server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
    final key = await SyncService.keyFromPhrase(phrase);
    return P2pHost._(server, key, phrase, await localAddress());
  }

  /// Подключается к устройству из приглашения и делает обмен.
  static Future<MergeReport> connect(PairInvite invite) async {
    final key = await SyncService.keyFromPhrase(invite.phrase);
    final socket = await Socket.connect(
      invite.host,
      invite.port,
      timeout: const Duration(seconds: 10),
    );
    try {
      final outgoing = await SyncService.buildPacket();
      final sealed = await SyncService.sealPacket(outgoing, key);
      writeFrame(socket, sealed);

      final incoming = await readFrame(socket).timeout(handshakeTimeout);
      final packet = await SyncService.openPacket(incoming, key);
      return SyncService.applyPacket(packet);
    } finally {
      socket.destroy();
    }
  }

  /// Адрес этого устройства в локальной сети — его показываем в QR.
  static Future<String> localAddress() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        // Домашние сети живут в частных диапазонах; публичный адрес тут
        // означал бы, что мы зовём подключиться из интернета.
        if (_isPrivate(address.address)) return address.address;
      }
    }
    return interfaces.isNotEmpty && interfaces.first.addresses.isNotEmpty
        ? interfaces.first.addresses.first.address
        : '127.0.0.1';
  }

  static bool _isPrivate(String ip) =>
      ip.startsWith('192.168.') ||
      ip.startsWith('10.') ||
      RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip);

  /// Кадр = четыре байта длины и тело: TCP отдаёт поток кусками, и без длины
  /// приёмник не знает, дочитал он пакет или нет.
  @visibleForTesting
  static void writeFrame(Socket socket, List<int> body) {
    final header = ByteData(4)..setUint32(0, body.length);
    socket.add(header.buffer.asUint8List());
    socket.add(body);
  }

  @visibleForTesting
  static Future<Uint8List> readFrame(Stream<Uint8List> socket) async {
    final buffer = BytesBuilder();
    int? expected;

    await for (final chunk in socket) {
      buffer.add(chunk);
      if (expected == null && buffer.length >= 4) {
        final bytes = buffer.toBytes();
        expected = ByteData.sublistView(bytes, 0, 4).getUint32(0);
        buffer
          ..clear()
          ..add(bytes.sublist(4));
      }
      if (expected != null && buffer.length >= expected) {
        return buffer.toBytes().sublist(0, expected);
      }
    }
    throw const SocketException('Соединение закрылось раньше времени');
  }
}

/// Поднятый приём: показывает приглашение и ждёт вторую сторону.
class P2pHost {
  final ServerSocket _server;
  final SecretKey _key;
  final String phrase;
  final String address;

  P2pHost._(this._server, this._key, this.phrase, this.address);

  int get port => _server.port;

  PairInvite get invite =>
      PairInvite(host: address, port: port, phrase: phrase);

  /// Ждёт подключение, обменивается пакетами и отдаёт отчёт о слиянии.
  Future<MergeReport> exchange() async {
    final socket = await _server.first.timeout(P2pService.handshakeTimeout);
    try {
      final incoming =
          await P2pService.readFrame(socket).timeout(P2pService.handshakeTimeout);
      final packet = await SyncService.openPacket(incoming, _key);
      final report = await SyncService.applyPacket(packet);

      final outgoing = await SyncService.buildPacket();
      final sealed = await SyncService.sealPacket(outgoing, _key);
      P2pService.writeFrame(socket, sealed);
      await socket.flush();
      return report;
    } finally {
      socket.destroy();
    }
  }

  Future<void> close() => _server.close();
}
