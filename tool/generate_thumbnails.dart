// Generates a still thumbnail (first frame, JPEG) for every animated GIF in
// assets/exercises/, into assets/exercises/thumbs/<same name>.jpg.
//
// ExerciseImage draws the still underneath the animated GIF: the stills are
// ~2 MB in total, so the web build keeps all of them in its offline cache —
// they show up instantly, and stand in for any GIF (~30 MB altogether) that
// hasn't been downloaded yet when there's no connection.
//
// Run from the project root after adding or replacing exercise GIFs:
//   dart run tool/generate_thumbnails.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const _maxSide = 240;
const _quality = 80;

void main() {
  final source = Directory('assets/exercises');
  final output = Directory('assets/exercises/thumbs')..createSync(recursive: true);
  var written = 0;
  var skipped = 0;

  for (final file in source.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.toLowerCase().endsWith('.gif')) continue;
    final target = File('${output.path}/${name.substring(0, name.length - 4)}.jpg');
    if (target.existsSync() && target.lastModifiedSync().isAfter(file.lastModifiedSync())) {
      skipped++;
      continue;
    }

    final decoded = _firstFrame(file);
    if (decoded == null) {
      stderr.writeln('No se pudo leer $name');
      continue;
    }
    final resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: decoded.width > _maxSide ? _maxSide : decoded.width)
        : img.copyResize(decoded, height: decoded.height > _maxSide ? _maxSide : decoded.height);
    // GIF transparency (if any) would turn black in a JPEG — flatten on white,
    // which is what the illustrations are drawn on anyway.
    final flattened = img.Image(width: resized.width, height: resized.height)
      ..clear(img.ColorRgb8(255, 255, 255));
    img.compositeImage(flattened, resized);
    target.writeAsBytesSync(img.encodeJpg(flattened, quality: _quality));
    written++;
  }
  stdout.writeln('Miniaturas: $written generadas, $skipped ya estaban al día.');
}

// Frame 0 only — no need to decode the whole animation.
img.Image? _firstFrame(File file) {
  final decoder = img.GifDecoder();
  final info = decoder.startDecode(file.readAsBytesSync());
  if (info == null) return null;
  return decoder.decodeFrame(0);
}
