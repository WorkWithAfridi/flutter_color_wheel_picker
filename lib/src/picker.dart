import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller.dart';
import 'wheel.dart';

/// A hue ring surrounding a saturation/value square.
///
/// Supply [controller] for programmatic selection and streams, or use
/// [initialColor] and [onChanged] for a self-contained picker. Changes are live.
/// Alpha is preserved; this picker does not include an opacity control.
class ColorWheelPicker extends StatefulWidget {
  const ColorWheelPicker(
      {super.key,
      this.controller,
      this.initialColor = const Color(0xFFFF0000),
      this.onChanged,
      this.size = 220,
      this.semanticLabel = 'Color picker',
      this.hueLabel = 'Hue',
      this.saturationLabel = 'Saturation',
      this.brightnessLabel = 'Brightness'})
      : assert(size >= 120 && size < double.infinity);

  /// External selection state. The caller retains ownership and disposal.
  final ColorPickerController? controller;

  /// Used once when this widget creates its own controller.
  final Color initialColor;

  /// User changes only; programmatic updates are available on the controller.
  final ValueChanged<Color>? onChanged;

  /// Requested square size in logical pixels; finite and at least 120.
  final double size;

  /// Accessible label for the picker group.
  final String semanticLabel;

  /// Accessible label for the adjustable hue channel.
  final String hueLabel;

  /// Accessible label for the adjustable saturation channel.
  final String saturationLabel;

  /// Accessible label for the adjustable brightness channel.
  final String brightnessLabel;

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  ColorPickerController? _owned;
  bool _focused = false;
  ColorPickerController get _controller => widget.controller ?? _owned!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _owned = ColorPickerController(initialColor: widget.initialColor);
    }
  }

  @override
  void didUpdateWidget(covariant ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      // Preserve selection when returning to internal state. Never dispose
      // a controller supplied by the caller.
      final previous = oldWidget.controller?.color ?? _owned!.color;
      _owned?.dispose();
      _owned = widget.controller == null
          ? ColorPickerController(initialColor: previous)
          : null;
    }
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  // Route pointer, keyboard and semantic edits through the same update path.
  void _change(HSVColor value) {
    final previous = _controller.color.toARGB32();
    _controller.setHsvColor(value);
    if (previous != _controller.color.toARGB32())
      widget.onChanged?.call(_controller.color);
  }

  // Each channel is independently adjustable by assistive technology.
  Widget _channel(
      {required String label,
      required double value,
      required double max,
      required double step,
      required ValueChanged<double> change}) {
    String format(double number) =>
        max == 1 ? '${(number * 100).round()}%' : '${number.round()} degrees';
    return Semantics(
        label: label,
        slider: true,
        value: format(value),
        increasedValue: format((value + step).clamp(0, max)),
        decreasedValue: format((value - step).clamp(0, max)),
        onIncrease: () => change((value + step).clamp(0, max)),
        onDecrease: () => change((value - step).clamp(0, max)),
        child: const SizedBox.expand());
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final hsv = _controller.hsvColor;
          return Focus(
            onFocusChange: (focused) => setState(() => _focused = focused),
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent)
                return KeyEventResult.ignored;
              final key = event.logicalKey;
              final horizontal = key == LogicalKeyboardKey.arrowRight ||
                  key == LogicalKeyboardKey.arrowLeft;
              final vertical = key == LogicalKeyboardKey.arrowUp ||
                  key == LogicalKeyboardKey.arrowDown;
              if (!horizontal && !vertical) return KeyEventResult.ignored;
              final increase = key == LogicalKeyboardKey.arrowRight ||
                  key == LogicalKeyboardKey.arrowUp;
              final delta = increase ? .01 : -.01;
              // Arrows mirror the square axes; Shift uses circular hue instead.
              if (HardwareKeyboard.instance.isShiftPressed) {
                _change(
                    hsv.withHue((hsv.hue + (increase ? 1 : -1) + 360) % 360));
              } else if (horizontal) {
                _change(
                    hsv.withSaturation((hsv.saturation + delta).clamp(0, 1)));
              } else {
                _change(hsv.withValue((hsv.value + delta).clamp(0, 1)));
              }
              return KeyEventResult.handled;
            },
            child: Semantics(
              label: widget.semanticLabel,
              child: Container(
                width: widget.size,
                height: widget.size,
                foregroundDecoration: _focused
                    ? BoxDecoration(
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2),
                        borderRadius: BorderRadius.circular(12))
                    : null,
                child: Stack(children: [
                  Positioned.fill(
                      child: ExcludeSemantics(
                          child: FittedBox(
                              child: RawColorWheelPicker(
                                  color: _controller.color,
                                  hsvColor: hsv,
                                  onChanged: _change)))),
                  // Semantic overlays expose channels without intercepting
                  // pointer gestures handled by the painted wheel below.
                  Positioned.fill(
                      child: IgnorePointer(
                          child: _channel(
                              label: widget.hueLabel,
                              value: hsv.hue,
                              max: 359,
                              step: 1,
                              change: (value) => _change(hsv.withHue(value))))),
                  Positioned(
                      left: widget.size * .25,
                      top: widget.size * .25,
                      width: widget.size * .5,
                      height: widget.size * .25,
                      child: IgnorePointer(
                          child: _channel(
                              label: widget.saturationLabel,
                              value: hsv.saturation,
                              max: 1,
                              step: .01,
                              change: (value) =>
                                  _change(hsv.withSaturation(value))))),
                  Positioned(
                      left: widget.size * .25,
                      top: widget.size * .5,
                      width: widget.size * .5,
                      height: widget.size * .25,
                      child: IgnorePointer(
                          child: _channel(
                              label: widget.brightnessLabel,
                              value: hsv.value,
                              max: 1,
                              step: .01,
                              change: (value) =>
                                  _change(hsv.withValue(value))))),
                ]),
              ),
            ),
          );
        },
      );
}
