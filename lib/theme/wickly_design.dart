import 'package:flutter/material.dart';

/// Надстройка Wickly над дизайн-ДНК.
///
/// В ДНК живут тема, шрифты, формы и движение — их не трогаем. Здесь только то,
/// чего в ДНК нет и что должно быть одинаковым на всех 24 экранах Wickly:
/// шкала настроения, обложки дневников и ритм карточек ленты.
///
/// **Система (объявлена до пикселей):**
/// * типографика — из ДНК: Unbounded (`display/headline/title`), Onest (`body/label`);
/// * фон экрана `surface`, карточка `surfaceContainerHigh`, лист `surfaceContainer`;
/// * радиусы: карточка 28, чип-пилюля stadium, обложка 24, поле 18;
/// * ритм: поля экрана 16, между карточками 12, внутри карточки 16;
/// * заголовок секции — Unbounded w700 13px, `primary`, капсом с трекингом;
/// * любой цвет — только из `colorScheme`, кроме двух семантических палитр ниже;
/// * **ни теней, ни свечения нигде**: ни `boxShadow`, ни `elevation` больше
///   нуля. Интерфейс плоский, слои различаются цветом поверхности и формой.
///   Новую тень не добавляем даже там, где M3 ставит её по умолчанию — у FAB,
///   навбара и листов она снята в теме.
class WicklyDesign {
  const WicklyDesign._();

  /// Поля экрана и шаги ритма.
  static const double screenPad = 16;
  static const double gapCards = 12;
  static const double gapInside = 16;

  static const double radiusCard = 28;
  static const double radiusCover = 24;
  static const double radiusField = 18;

  /// Высота обложки в карточке ленты.
  static const double feedCoverHeight = 132;

  // ------------------------- Телефон и десктоп -------------------------
  //
  // Широкое окно — не растянутый телефон. С этой ширины нижняя панель уходит
  // вбок рельсом, лента раскладывается плиткой, а текст перестаёт тянуться во
  // всю ширину монитора: строка в полтора метра не читается.

  /// Поле экрана на широком окне. Шире телефонных 16: на мониторе интерфейс,
  /// прижатый к самому краю, выглядит незаконченным.
  static const double deskPad = 24;

  /// Шаг между карточками сетки на широком окне.
  static const double gapDesk = 16;

  /// Ширина, с которой интерфейс становится десктопным.
  static const double wide = 900;

  /// Ширина колонки, в которой удобно читать и писать.
  static const double readWidth = 780;

  /// Ширина, дальше которой не растягиваются экраны-списки (настройки, поиск).
  static const double listWidth = 960;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  /// Боковое поле экрана-колонки. На телефоне это обычные 16, на широком окне
  /// поле разрастается и держит колонку читаемой: строка во весь монитор
  /// теряется — глаз не находит начало следующей.
  static double sidePad(BuildContext context, {double column = readWidth}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < wide) return screenPad;
    final side = (w - column) / 2;
    return side > screenPad ? side : screenPad;
  }

  /// Сколько карточек в ряду ленты. `preferred` — выбор человека в настройках,
  /// 0 значит «по ширине окна».
  static int feedColumns(double bodyWidth, int preferred) {
    if (preferred > 0) return preferred.clamp(2, 6);
    return (bodyWidth / 380).floor().clamp(2, 6);
  }

  /// Сколько колонок влезет в сетку с плиткой шириной [tileWidth].
  /// На телефоне всегда две — макет рисовался под них.
  static int gridColumns(BuildContext context, double tileWidth) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < wide) return 2;
    return (w / tileWidth).floor().clamp(2, 8);
  }

  /// Высота плитки ленты. Растёт вместе с размером шрифта: иначе на крупном
  /// тексте заголовок с описанием не влезают в карточку.
  static double feedTileHeight(BuildContext context) =>
      252 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);

  // ----------------------------- Появление -----------------------------
  //
  // Правило одно на всё приложение:
  // * список или секции экрана — каскад сверху вниз через [revealDelay];
  // * замена содержимого на месте (фильтр, месяц, вкладка) — не появление, а
  //   `AnimatedSwitcher` со сдвигом по оси движения: элемент не «рождается»,
  //   он сменяется;
  // * карточка, открывающая экран, отдаёт обложку общим элементом (`Hero`).

  /// Шаг каскада между соседними элементами.
  static const Duration revealStep = Duration(milliseconds: 55);

  /// Дальше этого номера задержку не копим: ждать появления восьмого элемента
  /// полсекунды — это уже не «живо», а «тормозит».
  static const int revealMaxSteps = 5;

  /// Задержка появления элемента с номером [index].
  static Duration revealDelay(int index) =>
      revealStep * (index < revealMaxSteps ? index : revealMaxSteps);
}

/// Шкала настроения — пять ступеней от «плохо» до «отлично».
///
/// Это **семантические** цвета: как `error` в схеме, они не выводятся из seed,
/// иначе «плохо» и «отлично» окрасятся одинаково и график настроения потеряет
/// смысл. Единственное исключение из правила «цвет только из colorScheme»,
/// поэтому все обращения идут через этот класс, а не хардкодом по экранам.
class MoodPalette {
  const MoodPalette._();

  static const int levels = 5;

  // Значения взяты из дизайн-макета (--m1…--m5).
  static const List<Color> _light = [
    Color(0xFFC7584C), // плохо
    Color(0xFFD98A46), // так себе
    Color(0xFFD8B544), // норм
    Color(0xFF82B464), // хорошо
    Color(0xFF4A9E86), // отлично
  ];

  /// В тёмной теме те же оттенки, поднятые по светлоте: на тёмной поверхности
  /// исходные читаются как грязь.
  static const List<Color> _dark = [
    Color(0xFFE87C6F),
    Color(0xFFEBA765),
    Color(0xFFE8CB63),
    Color(0xFF9ED082),
    Color(0xFF6BBFA6),
  ];

  /// Цвет ступени [mood] (1..5). За пределами шкалы — приглушённый контур.
  static Color color(BuildContext context, int? mood) {
    if (mood == null || mood < 1 || mood > levels) {
      return Theme.of(context).colorScheme.outlineVariant;
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    return (dark ? _dark : _light)[mood - 1];
  }

  /// Контрастный цвет текста поверх [color].
  static Color on(BuildContext context, int? mood) {
    if (mood == null || mood < 1 || mood > levels) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    // Все пять оттенков средней светлоты: тёмный текст читается на любом.
    return const Color(0xFF1E1710);
  }

  /// Ключ словаря для подписи ступени.
  static String labelKey(int mood) => switch (mood) {
        1 => 'mood_1',
        2 => 'mood_2',
        3 => 'mood_3',
        4 => 'mood_4',
        _ => 'mood_5',
      };
}

/// Обложки дневников и записей без фотографии.
///
/// Восемь тёплых двухцветных градиентов — по одному на акцент из палитры
/// настроек, чтобы обложка дневника перекликалась с темой приложения.
class CoverPalette {
  const CoverPalette._();

  static const Map<String, List<Color>> _covers = {
    'amber': [Color(0xFFD6A95E), Color(0xFF8A6A34)],
    'plum': [Color(0xFFC07F8E), Color(0xFF6A5C86)],
    'teal': [Color(0xFF7FB0A6), Color(0xFF3F6B62)],
    'forest': [Color(0xFFA8B96A), Color(0xFF4E6F45)],
    'indigo': [Color(0xFF8A93A8), Color(0xFF4A5A72)],
    'rose': [Color(0xFF9E6B6B), Color(0xFF6B4A4A)],
    'terracotta': [Color(0xFFC99A63), Color(0xFF7D5A3F)],
    'olive': [Color(0xFFA8894F), Color(0xFF6B7A3F)],
  };

  static List<String> get keys => _covers.keys.toList();

  static const String fallback = 'amber';

  static List<Color> colors(String? key) =>
      _covers[key] ?? _covers[fallback]!;

  /// Градиент обложки. [key] — ключ из [keys]; неизвестный даёт амбру.
  static LinearGradient gradient(String? key) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors(key),
      );

  /// Устойчивая обложка «по умолчанию» для записи без фото: одна и та же
  /// запись всегда получает один и тот же градиент.
  static String forSeed(String seed) =>
      keys[seed.hashCode.abs() % keys.length];
}
