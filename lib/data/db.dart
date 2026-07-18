import 'package:sqlite_crdt/sqlite_crdt.dart';

/// Держатель открытой базы.
///
/// Существует ради проверяемости: репозитории ходят сюда, а не в
/// `AppDatabase`, который тянет `path_provider` (плагин Flutter). Благодаря
/// этому весь слой данных запускается в чистой Dart VM — `tool/db_smoke.dart`
/// гоняет настоящие репозитории на настоящем SQLite+CRDT.
///
/// Почему не `flutter test`: `sqlite_crdt` 3.x жёстко берёт изолят-фабрику
/// `databaseFactoryFfi`, и под `flutter_tester` изолят не завершается — тест
/// виснет. Поэтому БД проверяем отдельным смоук-раннером.
class Db {
  const Db._();

  static SqlCrdt? _crdt;

  static SqlCrdt get crdt => _crdt!;
  static bool get isReady => _crdt != null;

  static void attach(SqlCrdt crdt) => _crdt = crdt;
  static void detach() => _crdt = null;
}
