import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_color_picker/flutter_color_picker.dart';
import '../lib/main.dart';

void main() {
  testWidgets('example opens its own background dialog', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PickerExample()));
    expect(find.byType(ColorWheelPicker), findsOneWidget);
    await tester.ensureVisible(find.text('Choose background color'));
    await tester.tap(find.text('Choose background color'));
    await tester.pumpAndSettle();
    expect(find.text('Background Color'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.byType(ColorWheelPicker), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
