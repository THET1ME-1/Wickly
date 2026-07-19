import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/data/crypto.dart';
import 'package:wickly/data/media_store.dart';
import 'package:wickly/services/export_service.dart';

/// Бэкап шифруется фразой со случайной солью (формат v2 «WBK2»). Проверяем, что
/// круг создать→восстановить сходится, соль на каждый бэкап своя, а неверная
/// фраза его не открывает.
void main() {
  setUp(() => Crypto.instance.init('0123456789abcdef' * 4));

  test('Круг создать → восстановить, случайная соль, отказ на чужой фразе',
      () async {
    final tmp = Directory.systemTemp.createTempSync('wickly_backup');
    addTearDown(() => tmp.deleteSync(recursive: true));
    MediaStore.instance.configure(supportDir: tmp.path, tempDir: tmp.path);

    final dbPath = '${tmp.path}/wickly.db';
    final original = List<int>.generate(1000, (i) => i % 256);
    File(dbPath).writeAsBytesSync(original);

    final sealed = await BackupService.create(
        dbPath: dbPath, passphrase: 'long-secret-phrase');
    // Метка формата v2.
    expect(sealed.sublist(0, 4), [0x57, 0x42, 0x4B, 0x32]);

    final restored = '${tmp.path}/restored.db';
    final mediaKey = await BackupService.restore(
        sealed: sealed, passphrase: 'long-secret-phrase', dbPath: restored);
    expect(File(restored).readAsBytesSync(), original);
    expect(mediaKey, isNotNull);

    await expectLater(
      BackupService.restore(
          sealed: sealed, passphrase: 'wrong', dbPath: restored),
      throwsA(anything),
    );

    final again = await BackupService.create(
        dbPath: dbPath, passphrase: 'long-secret-phrase');
    expect(sealed.sublist(4, 20), isNot(again.sublist(4, 20)),
        reason: 'соль должна быть случайной на каждый бэкап');
  });
}
