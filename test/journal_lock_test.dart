import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wickly/data/app_prefs.dart';
import 'package:wickly/data/journal_lock.dart';

void main() {
  // Замок дневника раньше был только значком: записи закрытого дневника всё
  // равно лежали в ленте, находились поиском и уходили в экспорт.
  setUp(() {
    JournalLock.forget();
    JournalLock.debugSetLocked(const {});
  });

  test('Без PIN замок дневника ничего не прячет', () async {
    SharedPreferences.setMockInitialValues(const {});
    await AppPrefs.instance.load();
    JournalLock.debugSetLocked(const {'j-secret'});

    expect(AppPrefs.instance.hasPin, isFalse);
    expect(JournalLock.isHidden('j-secret'), isFalse,
        reason: 'запирать нечем — прятать нечестно');
  });

  test('С PIN записи запертого дневника прячутся', () async {
    SharedPreferences.setMockInitialValues(const {
      'lock_pin_hash': 'x',
      'lock_pin_salt': 'y',
    });
    await AppPrefs.instance.load();
    JournalLock.debugSetLocked(const {'j-secret'});

    expect(AppPrefs.instance.hasPin, isTrue);
    expect(JournalLock.isHidden('j-secret'), isTrue);
    expect(JournalLock.isHidden('j-open'), isFalse);
    expect(JournalLock.hiddenJournalIds, contains('j-secret'));
  });

  test('Разблокированный дневник виден до конца сеанса', () async {
    SharedPreferences.setMockInitialValues(const {
      'lock_pin_hash': 'x',
      'lock_pin_salt': 'y',
    });
    await AppPrefs.instance.load();
    JournalLock.debugSetLocked(const {'j-secret'});

    JournalLock.debugUnlock('j-secret');
    expect(JournalLock.isHidden('j-secret'), isFalse);

    // Общий замок приложения забывает разблокировки.
    JournalLock.forget();
    expect(JournalLock.isHidden('j-secret'), isTrue);
  });
}
