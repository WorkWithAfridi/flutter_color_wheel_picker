import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Internal canvas picker with shared painting and hit-testing geometry.
/// The public wheel supplies HSV state and rebuilds after selection changes.
class RawColorWheelPicker extends StatefulWidget {
  const RawColorWheelPicker({
    required this.color,
    this.hsvColor,
    required this.onChanged,
    this.size = 220,
    super.key,
  });

  final double size;
  final Color color;
  final HSVColor? hsvColor;
  final ValueChanged<HSVColor> onChanged;

  @override
  State<RawColorWheelPicker> createState() => _RawColorWheelPickerState();
}

class _RawColorWheelPickerState extends State<RawColorWheelPicker> {
  double get _size => widget.size;
  static const double _wheelThickness = 18;
  static const double _wheelGap = 12;
  static const double _cardRadius = 10;

  late HSVColor _color;
  _PickerDragTarget? _dragTarget;

  @override
  void initState() {
    super.initState();
    _color = widget.hsvColor ?? HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(covariant RawColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hsvColor != null) {
      _color = widget.hsvColor!;
      return;
    }
    if (oldWidget.color != widget.color) {
      _color = HSVColor.fromColor(widget.color);
    }
  }

  void _handlePanStart(Offset localPosition) {
    // Lock the gesture to its starting region, even if it crosses the gap.
    _dragTarget = _targetForPosition(localPosition);
    _updateColor(localPosition);
  }

  void _handlePanUpdate(Offset localPosition) {
    if (_dragTarget == null) return;
    _updateColor(localPosition);
  }

  void _handlePanEnd() {
    _dragTarget = null;
  }

  _PickerDragTarget? _targetForPosition(Offset localPosition) {
    final geometry = _PickerGeometry.fromSize(
      size: Size(_size, _size),
      wheelThickness: _wheelThickness,
      wheelGap: _wheelGap,
      cardRadius: _cardRadius,
    );
    final vector = localPosition - geometry.center;
    final distance = vector.distance;
    final isInSquare = geometry.cardBounds.contains(localPosition);
    final isInRing = distance >= geometry.ringInnerRadius &&
        distance <= geometry.ringOuterRadius;

    if (isInRing) return _PickerDragTarget.hue;
    if (isInSquare) return _PickerDragTarget.saturationValue;
    return null;
  }

  void _updateColor(Offset localPosition) {
    final geometry = _PickerGeometry.fromSize(
      size: Size(_size, _size),
      wheelThickness: _wheelThickness,
      wheelGap: _wheelGap,
      cardRadius: _cardRadius,
    );
    final vector = localPosition - geometry.center;

    switch (_dragTarget) {
      case _PickerDragTarget.hue:
        // Canvas y increases downward, matching the clockwise sweep gradient.
        final hue =
            (math.atan2(vector.dy, vector.dx) * 180 / math.pi + 360) % 360;
        _color = _color.withHue(hue);
        break;
      case _PickerDragTarget.saturationValue:
        // Clamp drags outside the square; top is full brightness, bottom black.
        final dx = ((localPosition.dx - geometry.cardRect.left) /
                geometry.cardRect.width)
            .clamp(0.0, 1.0);
        final dy = ((localPosition.dy - geometry.cardRect.top) /
                geometry.cardRect.height)
            .clamp(0.0, 1.0);
        _color = HSVColor.fromAHSV(_color.alpha, _color.hue, dx, 1 - dy);
        break;
      case null:
        return;
    }

    // The parent controls repainting; retain HSV without an RGB round-trip.
    widget.onChanged(_color);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        _handlePanStart(details.localPosition);
        _handlePanEnd();
      },
      onPanStart: (details) => _handlePanStart(details.localPosition),
      onPanUpdate: (details) => _handlePanUpdate(details.localPosition),
      onPanEnd: (_) => _handlePanEnd(),
      onPanCancel: _handlePanEnd,
      child: SizedBox(
        width: _size,
        height: _size,
        child: CustomPaint(
          painter: _CustomColorWheelPainter(
            color: _color,
            wheelThickness: _wheelThickness,
            wheelGap: _wheelGap,
            cardRadius: _cardRadius,
          ),
        ),
      ),
    );
  }
}

enum _PickerDragTarget { hue, saturationValue }

class _CustomColorWheelPainter extends CustomPainter {
  const _CustomColorWheelPainter({
    required this.color,
    required this.wheelThickness,
    required this.wheelGap,
    required this.cardRadius,
  });

  final HSVColor color;
  final double wheelThickness;
  final double wheelGap;
  final double cardRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _PickerGeometry.fromSize(
      size: size,
      wheelThickness: wheelThickness,
      wheelGap: wheelGap,
      cardRadius: cardRadius,
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = wheelThickness
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(
        Rect.fromCircle(
          center: geometry.center,
          radius: geometry.ringRadius,
        ),
      );
    canvas.drawCircle(geometry.center, geometry.ringRadius, ringPaint);

    final hueColor = HSVColor.fromAHSV(1, color.hue, 1, 1).toColor();
    // White-to-hue gives saturation; the black overlay supplies brightness.
    final saturationPaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white, hueColor],
      ).createShader(geometry.cardRect);
    canvas.drawRRect(geometry.cardBounds, saturationPaint);

    final valuePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.black],
      ).createShader(geometry.cardRect);
    canvas.drawRRect(geometry.cardBounds, valuePaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFD3DAE0)
      ..strokeWidth = 1.2;
    canvas.drawRRect(geometry.cardBounds, borderPaint);

    // Use the same coordinates for thumb placement and pointer selection.
    final hueAngle = color.hue * math.pi / 180;
    final hueThumb = Offset(
      geometry.center.dx + math.cos(hueAngle) * geometry.ringRadius,
      geometry.center.dy + math.sin(hueAngle) * geometry.ringRadius,
    );
    _paintThumb(canvas, hueThumb, color.toColor());

    final svThumb = Offset(
      geometry.cardRect.left + color.saturation * geometry.cardRect.width,
      geometry.cardRect.bottom - color.value * geometry.cardRect.height,
    );
    _paintThumb(canvas, svThumb, color.toColor(), radius: 10);
  }

  void _paintThumb(
    Canvas canvas,
    Offset center,
    Color fill, {
    double radius = 11,
  }) {
    final thumbFill = Paint()..color = fill;
    final thumbBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;
    final thumbShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.black.withValues(alpha: .12);

    canvas.drawCircle(center, radius, thumbShadow);
    canvas.drawCircle(center, radius, thumbFill);
    canvas.drawCircle(center, radius, thumbBorder);
  }

  @override
  bool shouldRepaint(covariant _CustomColorWheelPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.wheelThickness != wheelThickness ||
        oldDelegate.wheelGap != wheelGap ||
        oldDelegate.cardRadius != cardRadius;
  }
}

/// Shared dimensions keep the visible gradients and gesture regions aligned.
class _PickerGeometry {
  const _PickerGeometry({
    required this.center,
    required this.ringRadius,
    required this.ringInnerRadius,
    required this.ringOuterRadius,
    required this.cardRect,
    required this.cardBounds,
  });

  factory _PickerGeometry.fromSize({
    required Size size,
    required double wheelThickness,
    required double wheelGap,
    required double cardRadius,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringRadius =
        math.min(size.width, size.height) / 2 - wheelThickness / 2;
    final ringInnerRadius = ringRadius - wheelThickness / 2;
    final ringOuterRadius = ringRadius + wheelThickness / 2;
    // An inscribed square has half-diagonal equal to the available radius.
    final cardHalfExtent = (ringInnerRadius - wheelGap) / math.sqrt2;
    final cardRect = Rect.fromCenter(
      center: center,
      width: cardHalfExtent * 2,
      height: cardHalfExtent * 2,
    );
    final cardBounds = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(cardRadius),
    );

    return _PickerGeometry(
      center: center,
      ringRadius: ringRadius,
      ringInnerRadius: ringInnerRadius,
      ringOuterRadius: ringOuterRadius,
      cardRect: cardRect,
      cardBounds: cardBounds,
    );
  }

  final Offset center;
  final double ringRadius;
  final double ringInnerRadius;
  final double ringOuterRadius;
  final Rect cardRect;
  final RRect cardBounds;
}
