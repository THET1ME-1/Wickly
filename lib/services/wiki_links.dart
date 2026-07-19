import '../models/entry.dart';
import '../widgets/markdown_lite.dart';

/// Ссылки между записями — `[[Вечер у реки]]`, как в Obsidian.
///
/// Зачем: дневник живёт годами, и половина записей продолжает предыдущие.
/// Ссылка ставится прямо в текст и никакой отдельной таблицы не заводит —
/// значит, она переживает синхронизацию, экспорт и бэкап без единой строчки
/// новой схемы, а в выгруженном markdown остаётся читаемой.
///
/// Цель ссылки — заголовок записи, а не её id: id в тексте дневника выглядит
/// как мусор, и переписать такую ссылку рукой нельзя. Разрешение имени в
/// запись живёт здесь.
class WikiLinks {
  const WikiLinks._();

  /// `[[Что-нибудь]]` — без переносов строки внутри и без вложенных скобок.
  static final pattern = RegExp(r'\[\[([^\[\]\n]{1,120})\]\]');

  /// Все цели ссылок из текста записи, по порядку и без повторов.
  static List<String> targetsIn(String? source) {
    if (source == null || source.isEmpty) return const [];
    final seen = <String>{};
    final out = <String>[];
    for (final m in pattern.allMatches(source)) {
      final target = m.group(1)!.trim();
      if (target.isEmpty) continue;
      if (seen.add(_key(target))) out.add(target);
    }
    return out;
  }

  /// Как записать ссылку на [title] в текст.
  static String token(String title) => '[[${title.trim()}]]';

  /// Заголовок, которым запись видна другим записям.
  ///
  /// Свой заголовок, а если его нет — первая строка текста. Пустая запись
  /// целью ссылки быть не может: ссылаться не на что.
  static String? titleOf(Entry entry) {
    final own = entry.title?.trim();
    if (own != null && own.isNotEmpty) return own;
    final body = MarkdownLite.strip(entry.body);
    if (body.isEmpty) return null;
    return body.length <= 60 ? body : body.substring(0, 60);
  }

  /// Ищет запись по названию ссылки.
  ///
  /// Сравнение мягкое: регистр и лишние пробелы не считаются. Если подходят
  /// несколько записей, берём свежую — в дневнике ссылка почти всегда ведёт
  /// на последнее упоминание.
  static Entry? resolve(String target, List<Entry> entries) {
    final key = _key(target);
    if (key.isEmpty) return null;
    Entry? best;
    for (final e in entries) {
      final title = titleOf(e);
      if (title == null || _key(title) != key) continue;
      if (best == null || e.entryDate.isAfter(best.entryDate)) best = e;
    }
    return best;
  }

  /// Записи, которые ссылаются на [entry] — «упоминания» под записью.
  ///
  /// Обратные ссылки и есть смысл всей затеи: связь односторонняя в тексте,
  /// но человек хочет видеть её с обеих сторон.
  static List<Entry> backlinks(Entry entry, List<Entry> entries) {
    final title = titleOf(entry);
    if (title == null) return const [];
    final key = _key(title);
    return [
      for (final e in entries)
        if (e.id != entry.id)
          if (targetsIn(e.body).any((t) => _key(t) == key)) e,
    ]..sort((a, b) => b.entryDate.compareTo(a.entryDate));
  }

  /// Ключ сравнения: регистр и пробелы не важны.
  static String _key(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
