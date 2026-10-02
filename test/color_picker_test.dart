import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_color_picker/flutter_color_picker.dart';

void main() {
  test('stream broadcasts distinct colors and closes on disposal', () async {
    final controller = ColorPickerController();
    final first = <Color>[];
    final second = <Color>[];
    var done = false;
    controller.colors.listen(first.add, onDone: () => done = true);
    controller.colors.listen(second.add);
    controller.color = Colors.blue;
    controller.color = Colors.blue;
    expect(first.map((color) => color.toARGB32()), [Colors.blue.toARGB32()]);
    expect(second, first);
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(done, isTrue);
    expect(() => controller.color = Colors.red, throwsStateError);
  });

  test('HSV preserves hue at black and alpha', () {
    final controller = ColorPickerController();
    controller.setHsvColor(const HSVColor.fromAHSV(.5, 240, 1, 0));
    expect(controller.hsvColor.hue, 240);
    controller.setHsvColor(controller.hsvColor.withValue(1));
    expect(controller.color.b, 1);
    expect(controller.color.a, closeTo(.5, .01));
    controller.dispose();
  });

  testWidgets('tap on square updates callback and controller', (tester) async {
    final controller = ColorPickerController();
    Color? picked;
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: ColorWheelPicker(
                controller: controller,
                onChanged: (color) => picked = color))));
    await tester.tapAt(tester.getCenter(find.byType(ColorWheelPicker)));
    await tester.pump();
    expect(picked, controller.color);
    expect(controller.hsvColor.saturation, closeTo(.5, .01));
    expect(controller.hsvColor.value, closeTo(.5, .01));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('scaled wheel retains hue drag target outside the ring',
      (tester) async {
    final controller = ColorPickerController();
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: ColorWheelPicker(controller: controller, size: 330))));
    final center = tester.getCenter(find.byType(ColorWheelPicker));
    final gesture = await tester.startGesture(center + const Offset(150, 0));
    await gesture.moveTo(center + const Offset(150, 30));
    await tester.pump();
    await gesture.moveTo(center + const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    expect(controller.hsvColor.hue, closeTo(90, 1));
    expect(controller.hsvColor.saturation, 1);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
