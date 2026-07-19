import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/data/journal_lock.dart';
import 'package:wickly/models/entry.dart';

void main() {
  // Замок дневника раньше был только значком: записи закрытого дневника всё
  // равно лежали в ленте, находились поиском и уходили в экспорт.
  setUp(() {
    JournalLock.forget();
    JournalLock.debugSetLocked(const {});
  });

  test('Записи запертого дневника прячутся', () {
    JournalLock.debugSetLocked(const {'j-secret'});

    expect(JournalLock.isHidden('j-secret'), isTrue);
    expect(JournalLock.isHidden('j-open'), isFalse);
    expect(JournalLock.hiddenJournalIds, contains('j-secret'));
  });

  test('Замок дневника не зависит от кода приложения', () {
    // Пароль у дневника свой: раньше замок молчал, пока не задан PIN, и
    // «запертый» дневник лежал открытым.
    JournalLock.debugSetLocked(const {'j-secret'});

    expect(JournalLock.isHidden('j-secret'), isTrue);
    expect(JournalLock.needsUnlock('j-secret', true), isTrue);
    expect(JournalLock.needsUnlock('j-open', false), isFalse);
  });

  test('Разблокированный дневник виден до конца сеанса', () {
    JournalLock.debugSetLocked(const {'j-secret'});

    JournalLock.debugUnlock('j-secret');
    expect(JournalLock.isHidden('j-secret'), isFalse);

    // Общий замок приложения забывает разблокировки.
    JournalLock.forget();
    expect(JournalLock.isHidden('j-secret'), isTrue);
  });

  group('Пароль дневника', () {
    Journal withPassword(String password) {
      final salt = JournalLock.newSalt();
      return Journal(
        id: 'j-secret',
        name: 'Личное',
        locked: true,
        createdAt: DateTime(2026, 7, 19),
        passHash: JournalLock.hashPassword(password, salt),
        passSalt: salt,
      );
    }

    test('Подходит только свой пароль', () {
      final journal = withPassword('калитка');

      expect(JournalLock.matches(journal, 'калитка'), isTrue);
      expect(JournalLock.matches(journal, 'Калитка'), isFalse);
      expect(JournalLock.matches(journal, ''), isFalse);
    });

    test('У одного пароля в двух дневниках разные хэши', () {
      final a = withPassword('калитка');
      final b = withPassword('калитка');

      expect(a.passSalt, isNot(b.passSalt));
      expect(a.passHash, isNot(b.passHash),
          reason: 'по совпадению хэшей нельзя догадаться, что пароль тот же');
    });

    test('Дневник без пароля открыть нечем', () {
      final legacy = Journal(
        id: 'j-old',
        name: 'Старый',
        locked: true,
        createdAt: DateTime(2026, 7, 19),
      );

      expect(legacy.hasPassword, isFalse);
      expect(JournalLock.matches(legacy, ''), isFalse);
    });

    test('Пароль переживает запись в дневник и обратно', () {
      final journal = withPassword('калитка');
      final restored = Journal.fromStorage(
        journal.toRowColumns(),
        journal.toPayload(),
      );

      expect(JournalLock.matches(restored, 'калитка'), isTrue);
    });

    test('Снятие замка стирает пароль', () {
      final opened = withPassword('калитка')
          .copyWith(locked: false, clearPass: true);

      expect(opened.hasPassword, isFalse);
      expect(opened.toPayload().containsKey('pass'), isFalse);
    });
  });
}
