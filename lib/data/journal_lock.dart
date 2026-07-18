import 'package:meta/meta.dart';

import 'journal_repository.dart';

/// Замок отдельного дневника.
///
/// Тумблер «заблокирован» и значок замка в списке были и раньше, но не значили
/// ничего: записи закрытого дневника всё равно лежали в ленте, находились
/// поиском и уходили в экспорт. Здесь замок начинает работать.
///
/// Разблокировка живёт до конца сеанса: ходить за PIN на каждое открытие
/// дневника — быстрее выключить замок совсем. При уходе в фон общий замок
/// приложения всё равно закроет всё.
///
/// Здесь только состояние: файл лежит в слое данных, который обязан
/// собираться без Flutter (`tool/db_smoke.dart` гоняет его в чистой Dart VM).
/// Спрос PIN живёт в `widgets/journal_gate.dart`.
class JournalLock {
  const JournalLock._();

  static final Set<String> _locked = <String>{};
  static final Set<String> _unlocked = <String>{};

  /// Дневники, которые сейчас надо прятать из общих выборок.
  static Set<String> get hiddenJournalIds =>
      _locked.difference(_unlocked);

  /// Есть ли чем запирать — задан ли PIN. Приходит снаружи: слой данных не
  /// заглядывает в настройки, иначе он утащит за собой Flutter.
  static bool _armed = false;

  /// Перечитывает, какие дневники заперты. Зовётся после правок дневников и
  /// на старте: список нужен синхронно, выборки не могут ждать базу.
  static Future<void> refresh({required bool armed}) async {
    _armed = armed;
    final journals = await JournalRepository.instance.all();
    _locked
      ..clear()
      ..addAll(journals.where((j) => j.locked).map((j) => j.id));
    // Дневник разлочили насовсем — снимаем и сеансовую отметку.
    _unlocked.removeWhere((id) => !_locked.contains(id));
  }

  /// Прячем ли записи этого дневника прямо сейчас.
  static bool isHidden(String? journalId) =>
      _armed && journalId != null && hiddenJournalIds.contains(journalId);

  /// Нужен ли PIN, чтобы войти в этот дневник.
  static bool needsUnlock(String id, bool locked) =>
      _armed && locked && !_unlocked.contains(id);

  /// Дневник открыли — до конца сеанса больше не спрашиваем.
  static void markUnlocked(String id) => _unlocked.add(id);

  /// Забывает разблокировки — при выходе из дневника в замок приложения.
  static void forget() => _unlocked.clear();

  @visibleForTesting
  static set debugArmed(bool value) => _armed = value;

  @visibleForTesting
  static void debugSetLocked(Set<String> ids) => _locked
    ..clear()
    ..addAll(ids);

  @visibleForTesting
  static void debugUnlock(String id) => _unlocked.add(id);
}
