import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['CAPTURE_SHOWCASE'] != '1') return;
    final fontDir = Platform.environment['SHOWCASE_FONT_DIR'];
    if (fontDir == null)
      throw StateError(
          'Set SHOWCASE_FONT_DIR to Flutter bin/cache/artifacts/material_fonts');
    final roboto = FontLoader('Roboto');
    for (final weight in ['regular', 'medium', 'bold']) {
      roboto.addFont(File('$fontDir/roboto-$weight.ttf')
          .readAsBytes()
          .then((data) => ByteData.sublistView(data)));
    }
    await roboto.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(File('$fontDir/materialicons-regular.otf')
        .readAsBytes()
        .then((data) => ByteData.sublistView(data)));
    await icons.load();
  });
  for (final entry in {
    'desktop': const Size(1200, 900),
    'mobile': const Size(390, 1550)
  }.entries) {
    testWidgets('showcase fits ${entry.key} layout', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(seedColor: accent),
                  scaffoldBackgroundColor: const Color(0xFFF7F6F2),
                  inputDecorationTheme: const InputDecorationTheme(
                      filled: true, fillColor: Color(0xFFF8F8FA))),
              home: const PickerExample())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Color picker'), findsOneWidget);
      if (Platform.environment['CAPTURE_SHOWCASE'] == '1') {
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../screenshots/${entry.key}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
