import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'wickly_design.dart';

/// Короткие обращения к шкале настроения: цвет и подпись ступени.
///
/// Вынесено отдельно от [MoodPalette], потому что подпись тянет словарь, а сама
/// палитра должна оставаться чистой таблицей цветов.
class MoodPaletteX {
  const MoodPaletteX._();

  static Color of(BuildContext context, int? mood) =>
      MoodPalette.color(context, mood);

  static Color on(BuildContext context, int? mood) =>
      MoodPalette.on(context, mood);

  /// «Хорошо», «Так себе» — на языке интерфейса.
  static String label(int mood) => tr(MoodPalette.labelKey(mood));

  /// Все пять ступеней по порядку.
  static List<int> get levels =>
      List.generate(MoodPalette.levels, (i) => i + 1);
}

/// Кружок настроения — та же метка, что в ленте, календаре и статистике.
class MoodDot extends StatelessWidget {
  final int? mood;
  final double size;

  /// Обводка вместо заливки — для дней без записи в календаре.
  final bool hollow;

  const MoodDot({super.key, this.mood, this.size = 14, this.hollow = false});

  @override
  Widget build(BuildContext context) {
    final color = MoodPalette.color(context, mood);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hollow || mood == null ? Colors.transparent : color,
        border: hollow || mood == null
            ? Border.all(color: color, width: 1.6)
            : null,
      ),
    );
  }
}
