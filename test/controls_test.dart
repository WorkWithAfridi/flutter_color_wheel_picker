import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_color_picker/flutter_color_picker.dart';

void main() {
  testWidgets('HEX validates, parses RGB/ARGB and follows external selection',
      (tester) async {
    final controller = ColorPickerController();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ColorHexField(controller: controller))));
    await tester.enterText(find.byType(TextField), '#123456');
    expect(controller.color.toARGB32(), 0xFF123456);
    await tester.enterText(find.byType(TextField), '80123456');
    expect(controller.color.toARGB32(), 0x80123456);
    await tester.enterText(find.byType(TextField), 'bad-input');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.color.toARGB32(), 0x80123456);
    expect(
        find.text('Enter 6 RGB or 8 ARGB hexadecimal digits'), findsOneWidget);
    controller.color = const Color(0xFFABCDEF);
    await tester.pump();
    expect(find.text('#FFABCDEF'), findsOneWidget);
    expect(find.text('Enter 6 RGB or 8 ARGB hexadecimal digits'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('opacity preserves HSV and synchronizes the HEX field',
      (tester) async {
    final controller =
        ColorPickerController(initialColor: const Color(0xFF123456));
    final before = controller.hsvColor;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      ColorOpacitySlider(controller: controller),
      ColorHexField(controller: controller),
    ]))));
    await tester.tapAt(tester.getCenter(find.byType(Slider)));
    await tester.pump();
    expect(controller.hsvColor.alpha, closeTo(.5, .02));
    expect(controller.hsvColor.hue, before.hue);
    expect(controller.hsvColor.saturation, before.saturation);
    expect(controller.hsvColor.value, before.value);
    final hex =
        '#${controller.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    expect(find.text(hex), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('swatch broadcasts selection and marks it selected',
      (tester) async {
    final controller = ColorPickerController();
    final events = <Color>[];
    controller.colors.listen(events.add);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ColorSwatchPalette(
                controller: controller,
                colors: const [Color(0xFFFF0000), Color(0xFF0000FF)]))));
    await tester.tap(find.byType(InkWell).last);
    await tester.pump();
    expect(controller.color.toARGB32(), 0xFF0000FF);
    expect(events.single.toARGB32(), 0xFF0000FF);
    final node =
        tester.getSemantics(find.bySemanticsLabel('Select color #FF0000FF'));
    expect(
        node.getSemanticsData().flagsCollection.isSelected, ui.Tristate.isTrue);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('keyboard and semantics adjust HSV without losing alpha',
      (tester) async {
    final controller = ColorPickerController();
    controller.setHsvColor(const HSVColor.fromAHSV(.4, 120, .5, .5));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
        home: Center(child: ColorWheelPicker(controller: controller))));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.hsvColor.saturation, closeTo(.51, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(controller.hsvColor.value, closeTo(.51, .001));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(controller.hsvColor.hue, 121);
    final node = tester.getSemantics(find.bySemanticsLabel('Brightness'));
    tester.binding.renderViews.first.owner!.semanticsOwner!
        .performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(controller.hsvColor.value, closeTo(.52, .001));
    expect(controller.hsvColor.alpha, .4);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
