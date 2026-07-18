import '../l10n/strings.dart';
import '../models/catalog.dart';

/// Имя элемента каталога на языке интерфейса.
///
/// У встроенных эмоций, действий и трекеров имени в базе нет — там лежит ключ
/// (`emo_calm`), и словарь переводит его на все семь языков. Как только человек
/// переименовал элемент, имя оказывается в зашифрованном `enc` и побеждает ключ.
/// Поэтому переименованная «радость» остаётся собой при смене языка, а
/// нетронутая — переезжает вместе с интерфейсом.
class CatalogNames {
  const CatalogNames._();

  static String of(CatalogItem item) {
    if (item.name.trim().isNotEmpty) return item.name;
    final key = item.builtin;
    if (key != null && hasTr(key)) return tr(key);
    return key ?? '';
  }
}
