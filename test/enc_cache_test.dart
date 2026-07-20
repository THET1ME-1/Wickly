import 'package:flutter_test/flutter_test.dart';

import 'package:wickly/data/crypto.dart';
import 'package:wickly/data/enc_cache.dart';
import 'package:wickly/models/entry.dart';

// Запись, приехавшая с чужим ключом (синхронизация с устройства, куда не
// переносили бэкап), не расшифровывается. Раньше кэш молча отдавал пустую
// карту, запись выглядела пустой, и первое же сохранение затирало настоящий
// текст своим шифртекстом — насовсем.
void main() {
  const keyA =
      'aa11bb22cc33dd44ee55ff66'
      '0718293a4b5c6d7e8f90a1b2c3d4e5f60718293a';
  const keyB =
      '00112233445566778899aabb'
      'ccddeeff00112233445566778899aabbccddeeff';

  setUp(EncCache.clear);

  test('Чужой ключ: расшифровки нет, и это видно вызывающему', () async {
    Crypto.instance.init(keyA);
    final written = Entry.create(
      journalId: 'j1',
      title: 'Вечер у реки',
      body: 'Настоящий текст записи',
    );
    final enc = await Crypto.instance.encryptJson(written.toPayload());

    Crypto.instance.init(keyB);
    expect(await EncCache.decode(enc), isNull);
  });

  test(
    'Нечитаемая запись помечена и не отдаёт пустой текст на сохранение',
    () async {
      Crypto.instance.init(keyA);
      final written = Entry.create(
        journalId: 'j1',
        title: 'Вечер у реки',
        body: 'Настоящий текст записи',
      );
      final row = written.toRowColumns();
      final enc = await Crypto.instance.encryptJson(written.toPayload());

      Crypto.instance.init(keyB);
      final payload = await EncCache.decode(enc);
      final entry = Entry.fromStorage(
        row,
        payload ?? const {},
        readable: payload != null,
      );

      expect(entry.readable, isFalse);
      expect(entry.title, isNull);
    },
  );

  test('Дневник с чужим ключом теряет пароль замка только на вид', () async {
    Crypto.instance.init(keyA);
    final journal = Journal(
      id: 'j1',
      name: 'Личное',
      createdAt: DateTime.now(),
      locked: true,
      passHash: 'hash',
      passSalt: 'salt',
    );
    final enc = await Crypto.instance.encryptJson(journal.toPayload());

    Crypto.instance.init(keyB);
    final payload = await EncCache.decode(enc);
    final read = Journal.fromStorage(
      {'id': 'j1', 'locked': 1, 'created_at': 0},
      payload ?? const {},
      readable: payload != null,
    );

    // Пароль в памяти пуст, но признак не даёт сохранить эту пустоту в базу.
    expect(read.readable, isFalse);
    expect(read.passHash, isNull);
    expect(read.copyWith(color: 3).readable, isFalse);
  });

  test('Свой ключ: запись читается и считается годной', () async {
    Crypto.instance.init(keyA);
    final written = Entry.create(
      journalId: 'j1',
      title: 'Вечер у реки',
      body: 'Текст',
    );
    final row = written.toRowColumns();
    final enc = await Crypto.instance.encryptJson(written.toPayload());

    final payload = await EncCache.decode(enc);
    expect(payload, isNotNull);
    final entry = Entry.fromStorage(
      row,
      payload ?? const {},
      readable: payload != null,
    );
    expect(entry.readable, isTrue);
    expect(entry.title, 'Вечер у реки');
    expect(entry.body, 'Текст');
  });
}
