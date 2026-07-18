import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../screens/lock_screen.dart';
import 'app_prefs.dart';
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
class JournalLock {
  const JournalLock._();

  static final Set<String> _locked = <String>{};
  static final Set<String> _unlocked = <String>{};

  /// Дневники, которые сейчас надо прятать из общих выборок.
  static Set<String> get hiddenJournalIds =>
      _locked.difference(_unlocked);

  /// Замок вообще имеет смысл только когда есть чем запирать.
  static bool get _armed => AppPrefs.instance.hasPin;

  /// Перечитывает, какие дневники заперты. Зовётся после правок дневников и
  /// на старте: список нужен синхронно, выборки не могут ждать базу.
  static Future<void> refresh() async {
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

  /// Спрашивает PIN, если дневник заперт. Возвращает true, когда можно войти.
  static Future<bool> ensureOpen(BuildContext context, Journal journal) async {
    if (!_armed || !journal.locked || _unlocked.contains(journal.id)) {
      return true;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LockScreen(
          onUnlocked: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (ok == true) {
      _unlocked.add(journal.id);
      return true;
    }
    return false;
  }

  /// Забывает разблокировки — при выходе из дневника в замок приложения.
  static void forget() => _unlocked.clear();

  @visibleForTesting
  static void debugSetLocked(Set<String> ids) => _locked
    ..clear()
    ..addAll(ids);

  @visibleForTesting
  static void debugUnlock(String id) => _unlocked.add(id);
}
