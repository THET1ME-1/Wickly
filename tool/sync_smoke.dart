// Проверка синхронизации: две настоящие базы обмениваются пакетами.
//
//   dart run tool/sync_smoke.dart
//
// Проверяем то, ради чего вообще взят CRDT: слияние не теряет записи, порядок
// обмена не важен, повторное применение пакета безвредно, а правка одной и той
// же записи на двух устройствах сходится к одному результату на обоих.
import 'dart:io';
import 'dart:typed_data';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';
import 'package:wickly/data/crypto.dart';
import 'package:wickly/data/db.dart';
import 'package:wickly/data/entry_repository.dart';
import 'package:wickly/data/media_repository.dart';
import 'package:wickly/data/media_store.dart';
import 'package:wickly/data/schema.dart';
import 'package:wickly/models/entry.dart';
import 'package:wickly/models/media.dart';
import 'package:wickly/services/p2p_service.dart';
import 'package:wickly/services/sync_service.dart';

int _pass = 0, _fail = 0;
void _check(String n, bool ok) {
  ok ? _pass++ : _fail++;
  print('  ${ok ? '✓' : '✗'} $n');
}

late SqliteCrdt phone;
late SqliteCrdt laptop;

/// Выполняет действие «на устройстве»: слой данных глобальный, поэтому
/// переключаем держатель базы и возвращаем прежний обратно.
///
/// Возврат важен: без него вложенный вызов (собрать пакет на телефоне внутри
/// действия ноутбука) оставлял бы держатель на телефоне, и следующая операция
/// молча уходила бы не туда.
SqliteCrdt? _current;

Future<T> on<T>(SqliteCrdt device, Future<T> Function() action) async {
  final previous = _current;
  _current = device;
  Db.attach(device);
  try {
    return await action();
  } finally {
    _current = previous;
    if (previous != null) Db.attach(previous);
  }
}

Future<void> main() async {
  sqfliteFfiInit();
  Crypto.instance.init(
      '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff');
  final tmp = Directory.systemTemp.createTempSync('wickly_sync');
  MediaStore.instance
      .configure(supportDir: tmp.path, tempDir: '${tmp.path}/tmp');

  phone = await SqliteCrdt.openInMemory(
      version: Schema.version, onCreate: Schema.onCreate);
  laptop = await SqliteCrdt.openInMemory(
      version: Schema.version, onCreate: Schema.onCreate);
  await on(phone, () => Schema.ensureSeeds(phone, 'Личное'));
  await on(laptop, () => Schema.ensureSeeds(laptop, 'Личное'));

  final key = await SyncService.keyFromPhrase('море-лампа-кедр-ветер');
  final entries = EntryRepository.instance;

  print('\n— Фраза сопряжения —');
  final k2 = await SyncService.keyFromPhrase('  Море Лампа Кедр Ветер  ');
  _check('регистр и пробелы во фразе не важны',
      (await key.extractBytes()).toString() ==
          (await k2.extractBytes()).toString());
  final other = await SyncService.keyFromPhrase('море-лампа-кедр-сокол');
  _check('другая фраза даёт другой ключ',
      (await key.extractBytes()).toString() !=
          (await other.extractBytes()).toString());
  _check('сгенерированная фраза из четырёх слов',
      SyncService.generatePhrase().split('-').length == 4);
  // Повтор слова путает на слух и режет число сочетаний.
  var allDistinct = true;
  for (var i = 0; i < 50; i++) {
    final words = SyncService.generatePhrase().split('-');
    if (words.toSet().length != 4) allDistinct = false;
  }
  _check('слова во фразе не повторяются', allDistinct);

  print('\n— Первый обмен —');
  final e1 = Entry.create(
      journalId: Schema.defaultJournalId, title: 'С телефона', body: 'Вечер');
  await on(phone, () => entries.insert(e1));

  final packet = await on(phone, () => SyncService.buildPacket());
  final sealed = await SyncService.sealPacket(packet, key);
  final opened = await SyncService.openPacket(sealed, key);
  final report = await on(laptop, () => SyncService.applyPacket(opened));
  _check('пакет доехал', report.rows > 0);
  _check('запись видна на ноутбуке',
      (await on(laptop, () => entries.getById(e1.id)))?.title == 'С телефона');

  print('\n— Чужим ключом не открыть —');
  var rejected = false;
  try {
    await SyncService.openPacket(sealed, other);
  } catch (_) {
    rejected = true;
  }
  _check('пакет не читается чужой фразой', rejected);

  print('\n— Повтор и встречный обмен —');
  await on(laptop, () => SyncService.applyPacket(opened));
  _check('повторное применение не двоит записи',
      (await on(laptop, () => entries.allEntries())).length == 1);

  final e2 = Entry.create(
      journalId: Schema.defaultJournalId, title: 'С ноутбука', body: 'Утро');
  await on(laptop, () => entries.insert(e2));
  final back = await on(laptop, () => SyncService.buildPacket());
  await on(phone, () => SyncService.applyPacket(back));
  _check('встречные записи сошлись на телефоне',
      (await on(phone, () => entries.allEntries())).length == 2);

  print('\n— Правка одной записи на двух устройствах —');
  // Телефон правит раньше, ноутбук — позже: побеждает поздняя правка,
  // и обе стороны должны прийти к одному значению.
  final onPhone = (await on(phone, () => entries.getById(e1.id)))!;
  await on(phone, () => entries.update(onPhone.copyWith(title: 'Правка телефона')));
  await Future.delayed(const Duration(milliseconds: 5));
  final onLaptop = (await on(laptop, () => entries.getById(e1.id)))!;
  await on(laptop, () => entries.update(onLaptop.copyWith(title: 'Правка ноутбука')));

  final fromPhone = await on(phone, () => SyncService.buildPacket());
  final fromLaptop = await on(laptop, () => SyncService.buildPacket());
  await on(laptop, () => SyncService.applyPacket(fromPhone));
  await on(phone, () => SyncService.applyPacket(fromLaptop));

  final titlePhone = (await on(phone, () => entries.getById(e1.id)))?.title;
  final titleLaptop = (await on(laptop, () => entries.getById(e1.id)))?.title;
  _check('устройства сошлись на одном значении', titlePhone == titleLaptop);
  _check('победила поздняя правка', titlePhone == 'Правка ноутбука');

  print('\n— Удаление —');
  await on(phone, () => entries.delete(e2.id));
  final deletion = await on(phone, () => SyncService.buildPacket());
  await on(laptop, () => SyncService.applyPacket(deletion));
  _check('удаление доехало',
      (await on(laptop, () => entries.getById(e2.id))) == null);

  print('\n— Вложения —');
  final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
  final name = await MediaStore.instance.put(bytes, ext: 'jpg');
  await on(
      phone,
      () => MediaRepository.instance.insert(
          Media.create(entryId: e1.id, kind: MediaKind.photo, file: name)));
  final withMedia = await on(phone, () => SyncService.buildPacket());
  _check('вложение уехало вместе с пакетом',
      (withMedia['media'] as Map).containsKey(name));
  await on(laptop, () => SyncService.applyPacket(withMedia));
  _check('вложение видно на ноутбуке',
      (await on(laptop, () => MediaRepository.instance.forEntry(e1.id))).length == 1);

  print('\n— Папка обмена —');
  final folder = Directory('${tmp.path}/folder');
  await SyncFolder.writePacket(folder, sealed, 'phone-node');
  _check('свой пакет не читаем как чужой',
      SyncFolder.foreignPackets(folder, 'phone-node').isEmpty);
  _check('чужой пакет находится',
      SyncFolder.foreignPackets(folder, 'laptop-node').length == 1);

  print('\n— Прямой обмен по сети —');
  // Держатель базы в процессе один, поэтому обе роли одновременно живут только
  // в тесте: сторона-приёмник тут не трогает базу, а принятое применяется
  // вручную уже при нужном устройстве.
  final e3 = Entry.create(
      journalId: Schema.defaultJournalId, title: 'Только на ноутбуке');
  await on(laptop, () => entries.insert(e3));
  final e4 = Entry.create(
      journalId: Schema.defaultJournalId, title: 'Только на телефоне');
  await on(phone, () => entries.insert(e4));

  final laptopBytes = await SyncService.sealPacket(
      await on(laptop, () => SyncService.buildPacket()), key);

  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final received = server.first.then((socket) async {
    final incoming = await P2pService.readFrame(socket);
    P2pService.writeFrame(socket, laptopBytes);
    await socket.flush();
    await socket.close();
    return incoming;
  });

  final invite = PairInvite(
      host: '127.0.0.1', port: server.port, phrase: 'море-лампа-кедр-ветер');
  _check('приглашение читается обратно',
      PairInvite.decode(invite.encode())?.port == invite.port);

  Db.attach(phone);
  final clientReport = await P2pService.connect(invite);
  final sealedFromPhone = await received;
  await server.close();
  await on(laptop,
      () async => SyncService.applyPacket(
          await SyncService.openPacket(sealedFromPhone, key)));

  _check('телефон принял пакет по сети', clientReport.rows > 0);
  _check('запись ноутбука приехала на телефон',
      (await on(phone, () => entries.getById(e3.id))) != null);
  _check('запись телефона приехала на ноутбук',
      (await on(laptop, () => entries.getById(e4.id))) != null);

  await phone.close();
  await laptop.close();
  Db.detach();
  tmp.deleteSync(recursive: true);

  print('\n$_pass пройдено, $_fail провалено');
  exit(_fail == 0 ? 0 : 1);
}
