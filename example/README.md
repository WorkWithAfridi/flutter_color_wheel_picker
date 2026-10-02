# Color picker example

This Flutter application demonstrates the package widget and color stream.
The application owns its dialog, preview and confirmation buttons in
`lib/color_picker_dialog.dart`. No third-party packages are required.

```sh
flutter pub get
flutter run
```

Tap or drag the inline picker, adjust opacity, enter HEX, or select a preset
to update the live swatch and ARGB value. Tab to the wheel and use arrows for
saturation/brightness, or Shift + arrows for hue.
Open Background Color to edit a provisional selection; Apply updates the
inline picker, while Cancel leaves the confirmed selection unchanged.

Android and web runners are included. Run `flutter test` for example tests.

## README screenshots

Desktop and mobile renders are saved in `../screenshots`.
To regenerate with real fonts, set `CAPTURE_SHOWCASE=1` and
`SHOWCASE_FONT_DIR` to your Flutter SDK's `bin/cache/artifacts/material_fonts`,
then run `flutter test test/showcase_test.dart` from this directory.
