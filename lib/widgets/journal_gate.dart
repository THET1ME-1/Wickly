import 'package:flutter/material.dart';

import '../data/journal_lock.dart';
import '../models/entry.dart';
import '../screens/lock_screen.dart';

/// Спрашивает PIN перед входом в запертый дневник.
///
/// Живёт отдельно от [JournalLock]: тот лежит в слое данных, который обязан
/// собираться без Flutter, а здесь нужен и `BuildContext`, и экран замка.
Future<bool> openJournalGate(BuildContext context, Journal journal) async {
  if (!JournalLock.needsUnlock(journal.id, journal.locked)) return true;

  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => LockScreen(
        onUnlocked: () => Navigator.of(ctx).pop(true),
      ),
    ),
  );
  if (ok == true) {
    JournalLock.markUnlocked(journal.id);
    return true;
  }
  return false;
}
