import 'package:path_provider/path_provider.dart';
import 'package:sqlite_crdt/sqlite_crdt.dart';

import 'db.dart';
import 'schema.dart';

/// Открытие локального хранилища Wickly на устройстве.
///
/// Движок — SQLite; синхронизация — CRDT (метаданные слияния `hlc`, `modified`,
/// `is_deleted` добавляет [SqliteCrdt] поверх наших таблиц). База — источник
/// истины. Схема и миграции живут в [Schema], а сам файл открывается здесь —
/// это единственное место слоя данных, которое знает про плагины Flutter.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'wickly.db';

  /// Стабильный id дневника по умолчанию (на него ссылаются первые записи).
  static const defaultJournalId = Schema.defaultJournalId;

  SqliteCrdt? _crdt;

  SqlCrdt get crdt => _crdt!;
  bool get isReady => _crdt != null;

  /// Путь к файлу базы — нужен бэкапу.
  Future<String> get filePath async =>
      '${(await getApplicationSupportDirectory()).path}/$_dbName';

  /// Открывает базу приложения и гарантирует дневник по умолчанию.
  /// [defaultJournalName] — локализованное имя (передаётся из UI-слоя).
  Future<void> init({required String defaultJournalName}) async {
    if (_crdt != null) return;
    _crdt = await SqliteCrdt.open(
      await filePath,
      version: Schema.version,
      onCreate: Schema.onCreate,
      onUpgrade: Schema.onUpgrade,
    );
    Db.attach(_crdt!);
    await Schema.ensureSeeds(_crdt!, defaultJournalName);
  }

  Future<void> close() async {
    await _crdt?.close();
    _crdt = null;
    Db.detach();
  }
}
