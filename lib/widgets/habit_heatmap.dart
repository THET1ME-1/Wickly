import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/feedback.dart';

/// Тепловая карта привычки: недели столбцами, дни строками.
///
/// Смотреть на список галочек скучно, а на поле — видно характер: где месяц
/// ровный, где всё развалилось в отпуске. Свежая неделя справа, как в
/// календаре.
class HabitHeatmap extends StatelessWidget {
  /// Дни подряд, свежий — последний. Длина кратна семи не обязана быть.
  final List<bool> days;

  final Color? color;

  /// Тап по клетке: смещение дня назад от сегодня.
  final void Function(int daysAgo)? onToggle;

  const HabitHeatmap({
    super.key,
    required this.days,
    this.color,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;

    // Ровняем начало по понедельнику, чтобы строки означали дни недели.
    final today = DateTime.now();
    final lead = (today.weekday - 1 + 7) % 7;
    final padded = [
      ...List<bool?>.filled((7 - (days.length + lead) % 7) % 7, null),
      ...days.map<bool?>((d) => d),
      ...List<bool?>.filled(lead, null),
    ];
    final weeks = padded.length ~/ 7;

    return LayoutBuilder(
      builder: (context, box) {
        // Клетка подбирается под ширину: карта не должна прокручиваться, иначе
        // теряется главное — вид целиком.
        final cell = ((box.maxWidth - (weeks - 1) * 3) / weeks).clamp(6.0, 30.0);

        return SizedBox(
          height: cell * 7 + 6 * 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var w = 0; w < weeks; w++) ...[
                Column(
                  children: [
                    for (var d = 0; d < 7; d++) ...[
                      _cell(
                        context,
                        value: padded[w * 7 + d],
                        // Сколько дней назад эта клетка.
                        daysAgo: padded.length - lead - (w * 7 + d) - 1,
                        size: cell,
                        tint: tint,
                      ),
                      if (d < 6) const SizedBox(height: 3),
                    ],
                  ],
                ),
                if (w < weeks - 1) const SizedBox(width: 3),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _cell(
    BuildContext context, {
    required bool? value,
    required int daysAgo,
    required double size,
    required Color tint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // Пустая клетка — день за пределами истории: он не был пропущен, его
    // просто не было. Показываем прозрачным, а не «не сделано».
    if (value == null) {
      return SizedBox(width: size, height: size);
    }

    final future = daysAgo < 0;
    return GestureDetector(
      onTap: future || onToggle == null
          ? null
          : () {
              value ? Haptics.tap() : Haptics.commit();
              onToggle!(daysAgo);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: AppTheme.emphasized,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value
              ? tint
              : (future
                  ? Colors.transparent
                  : scheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
      ),
    );
  }
}
