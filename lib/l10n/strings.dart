import 'dict/core.dart';
import 'dict/feed.dart';
import 'dict/onboarding.dart';

import 'locale_controller.dart';

/// Перевод строки по ключу на текущий язык интерфейса.
///
/// Каждый ключ хранит переводы на все 7 языков в одном месте — так проще
/// расширять (одна запись = семь языков). Если перевода на выбранный язык нет —
/// откат: английский → русский → сам ключ.
String tr(String key) {
  final code = LocaleController.instance.code;
  final entry = _strings[key];
  if (entry == null) return key;
  return entry[code] ?? entry['en'] ?? entry['ru'] ?? key;
}

/// Перевод с подстановкой `{name}` → значение.
String trf(String key, Map<String, Object> params) {
  var s = tr(key);
  params.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// Есть ли такой ключ в словаре — нужно там, где имя приходит из данных
/// (встроенные эмоции и трекеры хранят ключ, свои — готовое имя).
bool hasTr(String key) => _strings.containsKey(key);

/// Словарь собирается из секций: `dict/core.dart`, `dict/onboarding.dart` и так
/// далее по экранам. Разбивка нужна, чтобы правка одного экрана не требовала
/// лезть в файл на три тысячи строк.
const Map<String, Map<String, String>> _strings = {
  ...coreStrings,
  ...onboardingStrings,
  ...feedStrings,
};
