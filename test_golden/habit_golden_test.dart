// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wickly/services/habit_stats.dart';
import 'package:wickly/theme/wickly_design.dart';
import 'package:wickly/widgets/habit_heatmap.dart';

import 'harness.dart';

/// Привычка была строкой из семи кружков. Снимок сторожит новый вид: поле
/// выполнения за пятнадцать недель.
void main() {
  testWidgets('Тепловая карта привычки', (tester) async {
    // История с характером: ровный отрезок, провал, свежая серия.
    final byDay = <int, double>{};
    final today = DateTime(2026, 7, 18);
    for (final gap in [
      ...List.generate(12, (i) => i), // свежая серия
      ...List.generate(20, (i) => i + 25), // ровный отрезок в прошлом
      50, 52, 55, 61, 68,
    ]) {
      final d = today.subtract(Duration(days: gap));
      byDay[d.year * 10000 + d.month * 100 + d.day] = 1;
    }

    await Harness.shoot(
      tester,
      'habit_heatmap',
      () => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(WicklyDesign.screenPad),
          child: Align(
            alignment: Alignment.topCenter,
            child: HabitHeatmap(
              days: HabitMath.history(byDay, days: 15 * 7, now: today),
            ),
          ),
        ),
      ),
    );
  });
}
