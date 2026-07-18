import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/data/journal_lock.dart';

void main() {
  // Замок дневника раньше был только значком: записи закрытого дневника всё
  // равно лежали в ленте, находились поиском и уходили в экспорт.
  setUp(() {
    JournalLock.forget();
    JournalLock.debugSetLocked(const {});
  });

  test('Без PIN замок дневника ничего не прячет', () {
    JournalLock.debugArmed = false;
    JournalLock.debugSetLocked(const {'j-secret'});

    expect(JournalLock.isHidden('j-secret'), isFalse,
        reason: 'запирать нечем — прятать нечестно');
  });

  test('С PIN записи запертого дневника прячутся', () {
    JournalLock.debugArmed = true;
    JournalLock.debugSetLocked(const {'j-secret'});

    expect(JournalLock.isHidden('j-secret'), isTrue);
    expect(JournalLock.isHidden('j-open'), isFalse);
    expect(JournalLock.hiddenJournalIds, contains('j-secret'));
  });

  test('Разблокированный дневник виден до конца сеанса', () {
    JournalLock.debugArmed = true;
    JournalLock.debugSetLocked(const {'j-secret'});

    JournalLock.debugUnlock('j-secret');
    expect(JournalLock.isHidden('j-secret'), isFalse);

    // Общий замок приложения забывает разблокировки.
    JournalLock.forget();
    expect(JournalLock.isHidden('j-secret'), isTrue);
  });
}
