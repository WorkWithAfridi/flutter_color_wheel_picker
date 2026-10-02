import 'package:flutter/material.dart';
import 'controller.dart';

/// Adjusts alpha while preserving the selected hue, saturation and brightness.
class ColorOpacitySlider extends StatelessWidget {
  const ColorOpacitySlider(
      {super.key,
      required this.controller,
      this.onChanged,
      this.label = 'Opacity'});

  /// Caller-owned selection shared with the other picker controls.
  final ColorPickerController controller;

  /// Called when a user adjustment changes the rendered ARGB color.
  final ValueChanged<Color>? onChanged;

  /// Visible and accessible opacity label.
  final String label;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$label ${(controller.hsvColor.alpha * 100).round()}%'),
              Slider(
                  value: controller.hsvColor.alpha,
                  semanticFormatterCallback: (value) =>
                      '$label ${(value * 100).round()}%',
                  onChanged: (value) {
                    final previous = controller.color.toARGB32();
                    controller
                        .setHsvColor(controller.hsvColor.withAlpha(value));
                    if (previous != controller.color.toARGB32())
                      onChanged?.call(controller.color);
                  }),
            ]),
      );
}

/// Edits RGB (six digits, opaque) or ARGB (eight digits), with optional #.
/// Valid complete input is applied immediately. Invalid input never changes
/// the selection. Unfinished input is retained until submitted or focus leaves.
class ColorHexField extends StatefulWidget {
  const ColorHexField(
      {super.key,
      required this.controller,
      this.onChanged,
      this.label = 'HEX color',
      this.invalidMessage = 'Enter 6 RGB or 8 ARGB hexadecimal digits'});

  /// Caller-owned selection shared with the other picker controls.
  final ColorPickerController controller;

  /// Valid user changes only, excluding programmatic selection updates.
  final ValueChanged<Color>? onChanged;

  /// Visible field label, supplied by the app for localization.
  final String label;

  /// Error displayed when an invalid entry is submitted or loses focus.
  final String invalidMessage;

  @override
  State<ColorHexField> createState() => _ColorHexFieldState();
}

class _ColorHexFieldState extends State<ColorHexField> {
  late final TextEditingController _text;
  final _focus = FocusNode();
  // Suppress controller-to-text synchronization during our own text update
  // so typing does not move the caret or replace partially entered input.
  bool _editing = false;
  String? _error;
  String get _hex =>
      '#${widget.controller.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _hex);
    widget.controller.addListener(_sync);
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(covariant ColorHexField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      // Detach from the previous owner before following the new selection.
      oldWidget.controller.removeListener(_sync);
      widget.controller.addListener(_sync);
      _sync();
    }
  }

  void _sync() {
    if (_editing) return;
    _text.value = TextEditingValue(
        text: _hex, selection: TextSelection.collapsed(offset: _hex.length));
    if (_error != null) setState(() => _error = null);
  }

  void _focusChanged() {
    if (!_focus.hasFocus) _apply(_text.text, validate: true);
  }

  void _apply(String input, {bool validate = false}) {
    // Match complete RGB or ARGB only. Invalid drafts leave selection intact;
    // validation feedback appears on submit or loss of focus.
    final digits = input.trim().replaceFirst(RegExp(r'^#'), '');
    final valid =
        RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(digits);
    setState(() => _error = !valid && validate ? widget.invalidMessage : null);
    if (!valid) return;
    // Six digits are opaque RGB. Eight digits follow Flutter ARGB ordering,
    // which differs from CSS eight-digit HEX ordering.
    final color =
        Color(int.parse(digits.length == 6 ? 'FF$digits' : digits, radix: 16));
    final previous = widget.controller.color.toARGB32();
    _editing = true;
    try {
      widget.controller.color = color;
    } finally {
      _editing = false;
    }
    if (previous != widget.controller.color.toARGB32())
      widget.onChanged?.call(widget.controller.color);
    if (validate) _sync();
  }

  @override
  void dispose() {
    // The field owns text/focus resources, but not the shared color controller.
    widget.controller.removeListener(_sync);
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _text,
        focusNode: _focus,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
            labelText: widget.label,
            hintText: '#RRGGBB / #AARRGGBB',
            errorText: _error,
            border: const OutlineInputBorder()),
        onChanged: (input) => _apply(input),
        onSubmitted: (input) => _apply(input, validate: true),
      );
}

/// Caller-supplied swatches. The app owns palette storage and recent colors.
class ColorSwatchPalette extends StatelessWidget {
  const ColorSwatchPalette(
      {super.key,
      required this.controller,
      required this.colors,
      this.onChanged,
      this.swatchSize = 44,
      this.semanticLabel = 'Select color'})
      : assert(swatchSize >= 44);

  /// Caller-owned selection shared with the other picker controls.
  final ColorPickerController controller;

  /// App-provided presets or recent colors; the package does not persist them.
  final List<Color> colors;

  /// Called when selecting a swatch changes the rendered ARGB color.
  final ValueChanged<Color>? onChanged;

  /// Size in logical pixels; at least 44 to preserve the touch target.
  final double swatchSize;

  /// Accessible button label prefix; each color adds its ARGB value.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            // Alpha is part of selection identity, not just the RGB channels.
            final selected = color.toARGB32() == controller.color.toARGB32();
            final hex =
                '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
            return Semantics(
              selected: selected,
              button: true,
              label: '$semanticLabel $hex',
              child: Tooltip(
                message: hex,
                child: SizedBox.square(
                  dimension: swatchSize,
                  child: Material(
                    color: color,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.black26,
                            width: selected ? 3 : 1)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        final previous = controller.color.toARGB32();
                        controller.color = color;
                        if (previous != controller.color.toARGB32())
                          onChanged?.call(controller.color);
                      },
                      child: selected
                          ? Icon(Icons.check,
                              color:
                                  ThemeData.estimateBrightnessForColor(color) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}
