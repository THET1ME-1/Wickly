import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Целое число, которое при изменении «набегает» от старого значения к новому
/// и слегка подпрыгивает (M3 pop). При уменьшении (отмена хода) — мягче.
///
/// Цвет/шрифт берутся из [style]. На первом построении значение показывается
/// сразу, без анимации.
class CountUpNumber extends StatefulWidget {
  final int value;
  final TextStyle style;
  final Duration duration;

  const CountUpNumber({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 480),
  });

  @override
  State<CountUpNumber> createState() => _CountUpNumberState();
}

class _CountUpNumberState extends State<CountUpNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  int _from = 0;
  bool _increased = false;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
  }

  @override
  void didUpdateWidget(covariant CountUpNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _from = old.value;
      _increased = widget.value > old.value;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        if (!_c.isAnimating) {
          return Text('${widget.value}', maxLines: 1, style: widget.style);
        }
        final t = _c.value;
        final e = Curves.easeOut.transform(t);
        final shown = (_from + (widget.value - _from) * e).round();
        final pop = 1 + (_increased ? 0.16 : 0.05) * math.sin(t * math.pi);
        return Transform.scale(
          scale: pop,
          child: Text('$shown', maxLines: 1, style: widget.style),
        );
      },
    );
  }
}
