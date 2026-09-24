// Builds web/icons/Icon-maskable-{192,512}.png from assets/branding/logo.png:
// the logo scaled into the maskable "safe zone" (inner 80% circle) on the
// same solid background as the Android adaptive icon. The previous maskable
// icons were just copies of the transparent regular ones, so launchers that
// crop icons to a circle/squircle cut the logo off and filled the gaps with
// an arbitrary color.
//
//   dart run tool/generate_maskable_icons.dart
import 'dart:io';

import 'package:image/image.dart' as img;

// Same as adaptive_icon_background in pubspec.yaml.
final _background = img.ColorRgb8(0x1E, 0x1B, 0x18);

void main() {
  final logo = img.decodePng(File('assets/branding/logo.png').readAsBytesSync())!;
  for (final size in [192, 512]) {
    final canvas = img.Image(width: size, height: size)..clear(_background);
    // 66% of the side keeps the whole square logo inside the 80% safe circle.
    final side = (size * 0.66).round();
    final scaled = img.copyResize(logo, width: side, height: side, interpolation: img.Interpolation.cubic);
    img.compositeImage(canvas, scaled, dstX: (size - side) ~/ 2, dstY: (size - side) ~/ 2);
    File('web/icons/Icon-maskable-$size.png').writeAsBytesSync(img.encodePng(canvas));
  }
  stdout.writeln('Iconos maskable generados.');
}
