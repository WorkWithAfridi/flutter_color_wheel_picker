import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color_wheel_picker/flutter_color_wheel_picker.dart';
import 'color_picker_dialog.dart';

const ink = Color(0xFF252638);
const muted = Color(0xFF797987);
const accent = Color(0xFF7562D9);
// App-owned presets demonstrate that palette contents are not package state.
const palette = [
  accent,
  Color(0xFFB897E9),
  Color(0xFFF19FAD),
  Color(0xFFF2BC82),
  Color(0xFF8BBDA9),
  Color(0xFF739BCB)
];

// Styling belongs to the consuming app; the picker adds no fonts or packages.
void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: accent),
        scaffoldBackgroundColor: const Color(0xFFF7F6F2),
        inputDecorationTheme: const InputDecorationTheme(
            filled: true, fillColor: Color(0xFFF8F8FA))),
    home: const PickerExample()));

/// Demonstrates synchronized inline controls and an app-owned dialog.
class PickerExample extends StatefulWidget {
  const PickerExample({super.key});
  @override
  State<PickerExample> createState() => _PickerExampleState();
}

class _PickerExampleState extends State<PickerExample> {
  // One screen-owned controller synchronizes the wheel, controls and preview.
  final controller = ColorPickerController(initialColor: accent);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    // The dialog edits a separate draft. Only Apply changes this screen.
    final color = await showColorPickerDialog(
        context: context,
        initialColor: controller.color,
        title: 'Background Color',
        accentColor: accent,
        subtitle: 'Adjust the color, opacity, or HEX value.');
    // The route may have closed while awaiting the dialog result.
    if (mounted && color != null) controller.color = color;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
        child: SingleChildScrollView(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: accent, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.palette_outlined,
                        color: Colors.white, size: 21)),
                const SizedBox(width: 12),
                const Expanded(
                    child: Text('flutter color wheel picker',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.5,
                            color: ink))),
                const Tag('EXAMPLE')
              ]),
              const SizedBox(height: 28),
              // Stack panels on narrow screens without changing picker state.
              LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth < 760)
                  return Column(children: [
                    _studio(),
                    const SizedBox(height: 20),
                    _preview()
                  ]);
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _studio()),
                      const SizedBox(width: 24),
                      Expanded(flex: 4, child: _preview())
                    ]);
              }),
            ]),
          ),
        ))),
      ));
  // Each package widget edits the same controller, so no manual wiring is needed.
  Widget _studio() => Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(
            children: [Expanded(child: Heading('Color picker')), Tag('HSV')]),
        const SizedBox(height: 6),
        const Text('Select a hue, then adjust saturation and brightness.',
            style: TextStyle(fontSize: 13, color: muted)),
        const SizedBox(height: 24),
        const Center(child: Eyebrow('HUE / SATURATION / BRIGHTNESS')),
        const SizedBox(height: 18),
        Center(child: ColorWheelPicker(controller: controller, size: 240)),
        const SizedBox(height: 22),
        ColorOpacitySlider(controller: controller),
        const SizedBox(height: 12),
        ColorHexField(controller: controller),
        const SizedBox(height: 24),
        const Eyebrow('PRESETS'),
        const SizedBox(height: 12),
        ColorSwatchPalette(controller: controller, colors: palette),
      ]));
  // Streams emit future changes only; initialData supplies the first preview.
  Widget _preview() => StreamBuilder<Color>(
      stream: controller.colors,
      initialData: controller.color,
      builder: (context, snapshot) {
        final color = snapshot.data ?? controller.color;
        // Display alpha first to match Flutter Color and the package HEX field.
        final hex =
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
        return Panel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Heading('Preview'),
          const SizedBox(height: 6),
          const Text('Transparency is shown over a checkerboard.',
              style: TextStyle(fontSize: 13, color: muted)),
          const SizedBox(height: 24),
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                  painter: const Checkerboard(),
                  child: Container(
                      height: 260, width: double.infinity, color: color))),
          const SizedBox(height: 24),
          const Eyebrow('SELECTED COLOR'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: SelectableText(hex,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.8,
                        color: ink))),
            IconButton(
                tooltip: 'Copy ARGB color',
                icon: const Icon(Icons.copy_rounded, size: 19),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: hex));
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Color copied'),
                        duration: Duration(seconds: 2)));
                })
          ]),
          const SizedBox(height: 5),
          const Feature(Icons.circle, 'Live preview'),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  onPressed: _open,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Choose background color'))),
        ]));
      });
}

/// Example-only container; presentation remains outside the package API.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE9E7E1)),
          boxShadow: [
            BoxShadow(
                color: ink.withValues(alpha: .035),
                blurRadius: 32,
                offset: const Offset(0, 10))
          ]),
      child: child);
}

/// Consistent section title used by both example panels.
class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 21, fontWeight: FontWeight.w600, color: ink));
}

/// Small label for a group of controls or color output.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.5,
          color: muted,
          fontWeight: FontWeight.w600));
}

/// Compact example and color-model labels.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFF0EDF9),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 9,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: accent)));
}

/// Inline icon and status label for the preview.
class Feature extends StatelessWidget {
  const Feature(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(fontSize: 11, color: muted))
      ]);
}

/// Paints an app-owned transparency backdrop under the selected color.
class Checkerboard extends CustomPainter {
  const Checkerboard();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFF8F8F8));
    // Alternate cells expose partial alpha without image assets.
    final paint = Paint()..color = const Color(0xFFE9E9EF);
    for (var y = 0; y < size.height; y += 12) {
      for (var x = 0; x < size.width; x += 12) {
        if ((x ~/ 12 + y ~/ 12).isEven)
          canvas.drawRect(
              Rect.fromLTWH(x.toDouble(), y.toDouble(), 12, 12), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant Checkerboard oldDelegate) => false;
}
