import 'package:flutter/material.dart';

import '../data/journal_lock.dart';
import '../data/journal_repository.dart';
import '../l10n/strings.dart';
import '../models/entry.dart';
import 'journal_password_sheet.dart';

/// Спрашивает пароль перед входом в запертый дневник.
///
/// Живёт отдельно от [JournalLock]: тот лежит в слое данных, который обязан
/// собираться без Flutter, а здесь нужен и `BuildContext`, и лист ввода.
Future<bool> openJournalGate(BuildContext context, Journal journal) async {
  if (!JournalLock.needsUnlock(journal.id, journal.locked)) return true;

  // Дневник заперли в версии, где замок спрашивал код приложения: флаг есть,
  // своего пароля нет. Открывать его нечем, поэтому просим придумать пароль
  // прямо сейчас — иначе замок превратится в дверь без ключа.
  if (!journal.hasPassword) return _setFirstPassword(context, journal);

  final access = await askJournalPassword(context, journal);
  switch (access) {
    case JournalAccess.denied:
      return false;
    case JournalAccess.granted:
      JournalLock.markUnlocked(journal.id);
      return true;
    case JournalAccess.lockRemoved:
      // Пароль забыт. Он не шифрует записи, только закрывает вход, поэтому
      // снятие замка ничего не теряет — новый пароль задаётся в настройках
      // дневника.
      await JournalRepository.instance
          .update(journal.copyWith(locked: false, clearPass: true));
      await JournalLock.refresh();
      return true;
  }
}

Future<bool> _setFirstPassword(BuildContext context, Journal journal) async {
  final created = await askNewJournalPassword(
    context,
    note: tr('journal_password_missing'),
  );
  if (created == null) return false;
  await JournalRepository.instance.update(
    journal.copyWith(passHash: created.hash, passSalt: created.salt),
  );
  JournalLock.markUnlocked(journal.id);
  return true;
}
