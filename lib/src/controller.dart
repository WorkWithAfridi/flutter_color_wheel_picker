import 'dart:async';
import 'package:flutter/material.dart';

/// Owns an HSV selection and emits distinct ARGB colors synchronously.
///
/// [colors] is a broadcast stream of future changes; read [color] for the
/// current selection. Dispose after all attached pickers are unmounted.
class ColorPickerController extends ChangeNotifier {
  /// Seeds the selection from [initialColor], preserving its alpha.
  ColorPickerController({Color initialColor = const Color(0xFFFF0000)})
      : _hsv = HSVColor.fromColor(initialColor);

  // Keep HSV rather than reconstructing it from RGB: black and gray lose hue.
  HSVColor _hsv;
  bool _disposed = false;
  final _events = StreamController<Color>.broadcast(sync: true);

  /// Current rendered color, including alpha.
  Color get color => _hsv.toColor();

  /// Current HSV channels, including hue retained at black or gray.
  HSVColor get hsvColor => _hsv;

  /// Future distinct ARGB changes; does not replay the current selection.
  /// Do not update this controller synchronously from a stream listener.
  Stream<Color> get colors => _events.stream;

  /// Replaces the selection by converting an RGB/ARGB color into HSV.
  set color(Color value) => setHsvColor(HSVColor.fromColor(value));

  /// Preserves hue even when saturation or brightness is zero.
  void setHsvColor(HSVColor value) {
    if (_disposed) throw StateError('ColorPickerController is disposed.');
    if (_hsv == value) return;
    // Stream consumers receive visible changes; widget listeners also need
    // HSV-only changes, such as moving hue while brightness is zero.
    final previous = color.toARGB32();
    _hsv = value;
    if (previous != color.toARGB32()) _events.add(color);
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    // Closing completes stream subscriptions without emitting a final color.
    _events.close();
    super.dispose();
  }
}
