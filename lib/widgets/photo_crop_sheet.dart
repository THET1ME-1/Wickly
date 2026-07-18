import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../services/photo_crop.dart';
import '../theme/app_theme.dart';
import '../theme/wickly_design.dart';
import 'sheet_scaffold.dart';

/// Соотношение обложки: баннер в читалке занимает всю ширину и 260 по высоте.
/// Режем ровно под него, иначе кадрируешь одно, а видишь другое.
const double kCoverAspect = 3 / 2;

/// Кадрирование снимка перед тем, как он станет обложкой.
///
/// Лист снизу, как все окна Wickly. Возвращает готовый JPEG или null, если
/// человек передумал.
Future<Uint8List?> showPhotoCropSheet(
  BuildContext context, {
  required Uint8List bytes,
}) =>
    showWicklySheet<Uint8List>(
      context,
      expand: true,
      builder: (_) => PhotoCropSheet(bytes: bytes),
    );

/// Тело листа. Открыто для снимков экрана в `test_golden`.
class PhotoCropSheet extends StatefulWidget {
  final Uint8List bytes;

  const PhotoCropSheet({super.key, required this.bytes});

  @override
  State<PhotoCropSheet> createState() => _PhotoCropSheetState();
}

class _PhotoCropSheetState extends State<PhotoCropSheet> {
  /// Своя ширина и высота снимка, до поворота. Нужны, чтобы посчитать, как он
  /// ложится в рамку; пока не известны — показываем крутилку.
  int? _srcW;
  int? _srcH;

  int _turns = 0;
  double _zoom = 1;
  Offset _offset = Offset.zero;

  /// Масштаб и смещение на начало жеста: складывать надо с ними, иначе картинка
  /// прыгает от каждого касания.
  double _zoomAtGestureStart = 1;
  Offset _offsetAtGestureStart = Offset.zero;
  Offset _focalAtGestureStart = Offset.zero;

  bool _working = false;

  @override
  void initState() {
    super.initState();
    _readSize();
  }

  Future<void> _readSize() async {
    // Размеры берём у самого движка картинок: он уже умеет всё, что открывает
    // Image.memory, и не тянет второй декодер.
    try {
      final image = await decodeImageFromList(widget.bytes);
      if (mounted) {
        setState(() {
          _srcW = image.width;
          _srcH = image.height;
        });
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  /// Размеры снимка с учётом поворота.
  (double, double) get _rotated {
    final w = (_srcW ?? 1).toDouble();
    final h = (_srcH ?? 1).toDouble();
    return _turns.isEven ? (w, h) : (h, w);
  }

  /// Во сколько раз снимок растянут, чтобы закрыть рамку целиком.
  double _baseScale(Size frame) {
    final (w, h) = _rotated;
    return math.max(frame.width / w, frame.height / h);
  }

  double _scale(Size frame) => _baseScale(frame) * _zoom;

  /// Держит рамку внутри снимка: за краем обложка получила бы пустую полосу.
  Offset _clampOffset(Offset raw, Size frame) {
    final (w, h) = _rotated;
    final scale = _scale(frame);
    final slackX = math.max(0.0, (w * scale - frame.width) / 2);
    final slackY = math.max(0.0, (h * scale - frame.height) / 2);
    return Offset(
      raw.dx.clamp(-slackX, slackX),
      raw.dy.clamp(-slackY, slackY),
    );
  }

  void _rotate(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _turns = (_turns + delta) % 4;
      // Повёрнутый кадр ложится в рамку иначе, и старое смещение теряет смысл.
      _zoom = 1;
      _offset = Offset.zero;
    });
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _turns = 0;
      _zoom = 1;
      _offset = Offset.zero;
    });
  }

  Future<void> _accept(Size frame) async {
    final (w, h) = _rotated;
    final scale = _scale(frame);

    // Где левый верхний угол снимка на экране, если центр рамки — начало
    // отсчёта, а снимок сдвинут на _offset.
    final imgLeft = frame.width / 2 + _offset.dx - w * scale / 2;
    final imgTop = frame.height / 2 + _offset.dy - h * scale / 2;

    setState(() => _working = true);
    final result = await compute(
      cropPhoto,
      CropJob(
        bytes: widget.bytes,
        quarterTurns: _turns,
        left: (-imgLeft / scale) / w,
        top: (-imgTop / scale) / h,
        width: (frame.width / scale) / w,
        height: (frame.height / scale) / h,
      ),
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _working = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(tr('cover_crop_failed'))));
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ready = _srcW != null && _srcH != null;

    return LayoutBuilder(
      builder: (context, outer) {
        // Рамка занимает ширину листа за вычетом полей; высота — из
        // соотношения обложки.
        final frameW = outer.maxWidth - WicklyDesign.screenPad * 2;
        final frame = Size(frameW, frameW / kCoverAspect);

        return SheetScaffold(
          expand: true,
          title: tr('cover'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          action: IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: ready && !_working ? () => _accept(frame) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: WicklyDesign.screenPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                if (!ready)
                  SizedBox(
                    height: frame.height,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else
                  _frame(scheme, frame),
                const SizedBox(height: 20),
                _zoomRow(scheme, frame, ready),
                const SizedBox(height: 12),
                _tools(scheme, ready),
                const SizedBox(height: 12),
                Text(
                  tr('cover_crop_hint'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 11.5,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Рамка кадра: снимок под ней двигается и тянется, за края не выходит.
  Widget _frame(ColorScheme scheme, Size frame) {
    final (w, h) = _rotated;
    final scale = _scale(frame);

    return GestureDetector(
      onScaleStart: (d) {
        _zoomAtGestureStart = _zoom;
        _offsetAtGestureStart = _offset;
        _focalAtGestureStart = d.localFocalPoint;
      },
      onScaleUpdate: (d) {
        setState(() {
          _zoom = (_zoomAtGestureStart * d.scale).clamp(1.0, 5.0);
          _offset = _clampOffset(
            _offsetAtGestureStart +
                (d.localFocalPoint - _focalAtGestureStart),
            frame,
          );
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WicklyDesign.radiusCover),
        child: SizedBox(
          width: frame.width,
          height: frame.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Фон под снимком: в прозрачных PNG иначе просвечивает лист.
              ColoredBox(
                color: scheme.surfaceContainerHighest,
                child: SizedBox.expand(),
              ),
              // Положение задаём через Positioned, а не сдвигом: обычный
              // ребёнок Stack ограничен шириной рамки и сплющивается, а
              // BoxFit.fill послушно растягивает картинку поперёк.
              Positioned(
                left: frame.width / 2 - w * scale / 2 + _offset.dx,
                top: frame.height / 2 - h * scale / 2 + _offset.dy,
                width: w * scale,
                height: h * scale,
                child: RotatedBox(
                  quarterTurns: _turns,
                  child: Image.memory(
                    widget.bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              if (_working)
                ColoredBox(
                  color: scheme.scrim.withValues(alpha: 0.45),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _zoomRow(ColorScheme scheme, Size frame, bool ready) => Row(
        children: [
          Text(
            tr('cover_crop_zoom'),
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Slider(
              value: _zoom,
              min: 1,
              max: 5,
              onChanged: ready && !_working
                  ? (v) => setState(() {
                        _zoom = v;
                        _offset = _clampOffset(_offset, frame);
                      })
                  : null,
            ),
          ),
        ],
      );

  Widget _tools(ColorScheme scheme, bool ready) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolButton(
            icon: Icons.rotate_left_rounded,
            label: tr('cover_crop_left'),
            onTap: ready && !_working ? () => _rotate(-1) : null,
          ),
          _ToolButton(
            icon: Icons.settings_backup_restore_rounded,
            label: tr('cover_crop_reset'),
            onTap: ready && !_working ? _reset : null,
          ),
          _ToolButton(
            icon: Icons.rotate_right_rounded,
            label: tr('cover_crop_right'),
            onTap: ready && !_working ? () => _rotate(1) : null,
          ),
        ],
      );
}

/// Кнопка панели: круг с подписью. 56 по стороне — палец попадает.
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ToolButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: enabled ? scheme.onSurface : scheme.outlineVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.bodyFont,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: enabled ? scheme.onSurfaceVariant : scheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
