import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as hash;
import 'package:meta/meta.dart';

import '../models/entry.dart';
import 'journal_repository.dart';

/// Замок отдельного дневника.
///
/// Тумблер «заблокирован» и значок замка в списке были и раньше, но не значили
/// ничего: записи закрытого дневника всё равно лежали в ленте, находились
/// поиском и уходили в экспорт. Здесь замок начинает работать.
///
/// Пароль у дневника **свой**, текстовый, и с кодом приложения не связан: код
/// впускает в приложение, пароль — в один дневник. Хранится солёным хэшем в
/// зашифрованном поле дневника (см. [Journal.passHash]), сам пароль никуда не
/// пишется.
///
/// Разблокировка живёт до конца сеанса: ходить за паролем на каждое открытие
/// дневника — быстрее выключить замок совсем. При уходе в фон общий замок
/// приложения всё равно закроет всё.
///
/// Здесь только состояние и хэш: файл лежит в слое данных, который обязан
/// собираться без Flutter (`tool/db_smoke.dart` гоняет его в чистой Dart VM).
/// Спрос пароля живёт в `widgets/journal_gate.dart`.
class JournalLock {
  const JournalLock._();

  static final Set<String> _locked = <String>{};
  static final Set<String> _unlocked = <String>{};

  static final StreamController<void> _changes =
      StreamController<void>.broadcast();

  /// Тик после каждой смены состояния. Лента держит записи запертых дневников
  /// под блюром, и после ввода пароля ей надо пересобрать выборки: сама база
  /// при этом не менялась, поэтому её поток молчит.
  static Stream<void> get changes => _changes.stream;

  /// Дневники, которые сейчас надо прятать из общих выборок.
  static Set<String> get hiddenJournalIds => _locked.difference(_unlocked);

  /// Перечитывает, какие дневники заперты. Зовётся после правок дневников и
  /// на старте: список нужен синхронно, выборки не могут ждать базу.
  static Future<void> refresh() async {
    final journals = await JournalRepository.instance.all();
    _locked
      ..clear()
      ..addAll(journals.where((j) => j.locked).map((j) => j.id));
    // Дневник разлочили насовсем — снимаем и сеансовую отметку.
    _unlocked.removeWhere((id) => !_locked.contains(id));
    _notify();
  }

  /// Прячем ли записи этого дневника прямо сейчас.
  static bool isHidden(String? journalId) =>
      journalId != null && hiddenJournalIds.contains(journalId);

  /// Нужен ли пароль, чтобы войти в этот дневник.
  static bool needsUnlock(String id, bool locked) =>
      locked && !_unlocked.contains(id);

  /// Дневник открыли — до конца сеанса больше не спрашиваем.
  static void markUnlocked(String id) {
    if (_unlocked.add(id)) _notify();
  }

  /// Забывает разблокировки — при выходе из дневника в замок приложения.
  static void forget() {
    if (_unlocked.isEmpty) return;
    _unlocked.clear();
    _notify();
  }

  static void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  // ---------------------------- Пароль ----------------------------

  static final Random _random = Random.secure();

  /// Соль на дневник: у двух дневников с одним паролем хэши разные, и по
  /// совпадению хэшей нельзя догадаться, что пароль тот же.
  static String newSalt() => List.generate(
        16,
        (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();

  static String hashPassword(String password, String salt) =>
      hash.sha256.convert(utf8.encode('wickly-journal:$salt:$password'))
          .toString();

  /// Подходит ли пароль к дневнику.
  static bool matches(Journal journal, String password) =>
      journal.hasPassword &&
      hashPassword(password, journal.passSalt!) == journal.passHash;

  /// Пароль короче этого не принимаем: замок из двух символов — украшение.
  static const minLength = 4;

  @visibleForTesting
  static void debugSetLocked(Set<String> ids) => _locked
    ..clear()
    ..addAll(ids);

  @visibleForTesting
  static void debugUnlock(String id) => _unlocked.add(id);
}
