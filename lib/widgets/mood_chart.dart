import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/feedback.dart';
import '../theme/app_theme.dart';

/// Тренд настроения: мягкая линия с заливкой под ней.
///
/// Линия сглажена кривыми Безье — по ломаной из пяти ступеней тренд читается
/// как кардиограмма, а нужно видеть направление: вверх месяц шёл или вниз.
/// Пропущенные дни линию не рвут: тренд идёт по тем дням, где настроение есть.
class MoodChart extends StatelessWidget {
  /// Значения по дням; `null` — день без настроения.
  final List<double?> values;

  /// Подписи под краями и серединой графика.
  final String startLabel;
  final String middleLabel;
  final String endLabel;

  final double height;

  const MoodChart({
    super.key,
    required this.values,
    required this.startLabel,
    required this.middleLabel,
    required this.endLabel,
    this.height = 118,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 11,
      color: scheme.onSurfaceVariant,
    );

    return Column(
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: CustomPaint(
              painter: _ChartPainter(
                values: values,
                line: scheme.primary,
                fill: scheme.primary.withValues(alpha: 0.18),
                grid: scheme.outlineVariant.withValues(alpha: 0.5),
                background: scheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(startLabel, style: style),
            Text(middleLabel, style: style),
            Text(endLabel, style: style),
          ],
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double?> values;
  final Color line;
  final Color fill;
  final Color grid;
  final Color background;

  const _ChartPainter({
    required this.values,
    required this.line,
    required this.fill,
    required this.grid,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    if (values.isEmpty) return;

    // Сетка по ступеням шкалы — иначе высота линии ни о чём не говорит.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null) continue;
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);
      // Шкала 1..5 снизу вверх, с полями сверху и снизу.
      final t = ((v - 1) / 4).clamp(0.0, 1.0);
      final y = size.height - 10 - t * (size.height - 26);
      points.add(Offset(x, y));
    }
    if (points.isEmpty) return;

    final path = _smooth(points);

    // Заливка под линией.
    final area = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = fill);

    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Точка последнего дня — «где я сейчас».
    canvas.drawCircle(points.last, 4.5, Paint()..color = line);
  }

  /// Кубическое сглаживание по средним точкам: линия проходит через все
  /// значения и не даёт петель на резких перепадах.
  static Path _smooth(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length < 3) {
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }
    for (var i = 1; i < points.length - 1; i++) {
      final mid = Offset(
        (points[i].dx + points[i + 1].dx) / 2,
        (points[i].dy + points[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(points[i].dx, points[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.values != values || old.line != line;
}

/// Кольцо прогресса вокруг числа — трекеры воды, сна и шагов.
class ProgressRing extends StatelessWidget {
  final double progress;
  final double size;
  final double thickness;
  final Color? color;

  /// Что написано внутри кольца.
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 46,
    this.thickness = 4,
    this.color,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: AppTheme.emphasizedDecelerate,
        builder: (context, value, _) => CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color ?? scheme.primary,
            track: scheme.outlineVariant.withValues(alpha: 0.6),
            thickness: thickness,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  final double thickness;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(thickness / 2, thickness / 2) &
        Size(size.width - thickness, size.height - thickness);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    if (progress <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      base
        ..color = color
        ..strokeWidth = thickness,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Недельная сетка привычки: семь точек, закрашены выполненные дни.
class HabitWeek extends StatelessWidget {
  final List<bool> days;
  final Color? color;
  final ValueChanged<int>? onToggle;

  const HabitWeek({
    super.key,
    required this.days,
    this.color,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < days.length; i++)
          GestureDetector(
            onTap: onToggle == null
                ? null
                : () {
                    // Отметка привычки — жест «сделал»: подтверждаем телом.
                    days[i] ? Haptics.tap() : Haptics.commit();
                    onToggle!(i);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: AppTheme.emphasized,
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: days[i] ? tint : Colors.transparent,
                border: days[i]
                    ? null
                    : Border.all(color: scheme.outlineVariant, width: 1.6),
              ),
            ),
          ),
      ],
    );
  }
}
