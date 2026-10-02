import 'package:flutter/material.dart';
import 'package:flutter_color_picker/flutter_color_picker.dart';

/// Builds a custom preview beside the picker, such as an app-owned QR widget.
typedef ColorPickerPreviewBuilder = Widget Function(
    BuildContext context, Color color);

/// Returns the applied color, or null when cancelled or dismissed.
///
/// Live changes are delivered to [onChanged]. They are provisional until the
/// returned future completes with a color. The dialog owns its controller.
Future<Color?> showColorPickerDialog({
  required BuildContext context,
  Color initialColor = const Color(0xFFFF0000),
  String title = 'Choose Color',
  String? subtitle,
  String applyLabel = 'Apply',
  String cancelLabel = 'Cancel',
  Color? accentColor,
  ValueChanged<Color>? onChanged,
  ColorPickerPreviewBuilder? previewBuilder,
  bool barrierDismissible = true,
}) async {
  // A private draft isolates provisional edits from the caller's selection.
  final controller = ColorPickerController(initialColor: initialColor);
  try {
    return await showDialog<Color>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: SizedBox(
          width: 360,
          // Content can exceed the viewport when the keyboard is visible.
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (subtitle != null) ...[
                Align(alignment: Alignment.centerLeft, child: Text(subtitle)),
                const SizedBox(height: 24),
              ],
              LayoutBuilder(builder: (context, constraints) {
                final preview = AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => SizedBox.square(
                    dimension: 96,
                    child: previewBuilder?.call(context, controller.color) ??
                        DecoratedBox(
                            decoration: BoxDecoration(
                          color: controller.color,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD3DAE0)),
                        )),
                  ),
                );
                final picker = ColorWheelPicker(
                    controller: controller, onChanged: onChanged);
                // Keep the same controls usable in narrow mobile dialogs.
                if (constraints.maxWidth < 320) {
                  return Column(mainAxisSize: MainAxisSize.min, children: [
                    preview,
                    const SizedBox(height: 20),
                    FittedBox(child: picker),
                  ]);
                }
                return Row(children: [
                  preview,
                  const SizedBox(width: 12),
                  Expanded(child: FittedBox(child: picker)),
                ]);
              }),
              const SizedBox(height: 16),
              // Sharing the draft also keeps HEX and presets synchronized.
              ColorOpacitySlider(controller: controller, onChanged: onChanged),
              ColorHexField(controller: controller, onChanged: onChanged),
              const SizedBox(height: 16),
              ColorSwatchPalette(
                  controller: controller,
                  onChanged: onChanged,
                  colors: const [
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.black,
                    Colors.white,
                    Color(0xFFEA9070)
                  ]),
            ]),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          accentColor ?? Theme.of(context).colorScheme.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    // Return the current draft only on explicit confirmation.
                    onPressed: () =>
                        Navigator.of(context).pop(controller.color),
                    child: Text(applyLabel),
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(cancelLabel)),
                ],
              ))
        ],
      ),
    );
  } finally {
    // Every exit path, including barrier/back dismissal, releases draft state.
    controller.dispose();
  }
}
