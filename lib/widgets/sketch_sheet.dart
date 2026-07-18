import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../l10n/strings.dart';
import '../screens/settings_screen.dart';
import 'sheet_scaffold.dart';

/// Один мазок: точки, цвет и толщина.
class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;

  const _Stroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

/// Рисунок от руки прямо в записи.
///
/// Отдаёт готовый PNG — вложение хранится как обычная картинка, поэтому
/// показывается в ленте, в медиа-сетке и уезжает в экспорт наравне с фото.
Future<Uint8List?> showSketchSheet(BuildContext context) =>
    showWicklySheet<Uint8List>(
      context,
      expand: true,
      builder: (_) => const _SketchSheet(),
    );

class _SketchSheet extends StatefulWidget {
  const _SketchSheet();

  @override
  State<_SketchSheet> createState() => _SketchSheetState();
}

class _SketchSheetState extends State<_SketchSheet> {
  final _strokes = <_Stroke>[];
  final _boardKey = GlobalKey();

  Color _color = kWicklyPresets.first;
  double _width = 5;

  void _start(Offset p) => setState(() => _strokes.add(
      _Stroke(points: [p], color: _color, width: _width)));

  void _extend(Offset p) {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.last.points.add(p));
  }

  void _undo() {
    if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
  }

  /// Снимает нарисованное в PNG через слой репейнта — так в файл попадает
  /// ровно то, что человек видел, без пересборки сцены руками.
  Future<void> _accept() async {
    final boundary = _boardKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted || data == null) return;
    Navigator.of(context).pop(data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SheetScaffold(
      expand: true,
      title: tr('add_sketch'),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      action: IconButton(
        icon: const Icon(Icons.check_rounded),
        onPressed: _strokes.isEmpty ? null : _accept,
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RepaintBoundary(
                  key: _boardKey,
                  child: Container(
                    color: scheme.surfaceContainerLowest,
                    child: GestureDetector(
                      onPanStart: (d) => _start(d.localPosition),
                      onPanUpdate: (d) => _extend(d.localPosition),
                      child: CustomPaint(
                        painter: _SketchPainter(_strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: _strokes.isEmpty ? null : _undo,
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: tr('undo'),
                ),
                const SizedBox(width: 4),
                for (final c in kWicklyPresets.take(5)) ...[
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c
                              ? scheme.onSurface
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                // Три толщины кистью показаны самими точками — подписи не нужны.
                for (final w in const [3.0, 6.0, 11.0])
                  GestureDetector(
                    onTap: () => setState(() => _width = w),
                    child: Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      child: Container(
                        width: w + 4,
                        height: w + 4,
                        decoration: BoxDecoration(
                          color: _width == w
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<_Stroke> strokes;
  const _SketchPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke.points,
            paint..strokeWidth = stroke.width);
        continue;
      }
      final path = Path()
        ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SketchPainter old) => true;
}
