// Writes build/web/sw.js (the PWA's offline service worker) from
// tool/sw_template.js, with the list of files to precache and a version
// derived from their contents — so every deploy that changes anything also
// changes sw.js, which is what makes browsers pick up the new build.
//
// Run after `flutter build web` (the GitHub Pages workflow does):
//   dart run tool/generate_service_worker.dart
import 'dart:convert';
import 'dart:io';

const _buildDir = 'build/web';

// Left out of the precache:
// - the animated exercise GIFs (~30 MB): lists use still thumbnails, and each
//   GIF is cached the first time its detail screen is opened;
// - both CanvasKit engines: the service worker precaches only the one the
//   browser will use (see engineFiles in the template);
// - other renderers' engines, debug symbols/maps and Flutter's own
//   (self-unregistering) service worker.
bool _excluded(String path) =>
    (path.startsWith('assets/assets/exercises/') && path.toLowerCase().endsWith('.gif')) ||
    path.startsWith('canvaskit/') ||
    path.endsWith('.symbols') ||
    path.endsWith('.map') ||
    path.endsWith('.deps') ||
    path.endsWith('.dart') ||
    path == 'flutter_service_worker.js' ||
    path == 'sw.js' ||
    path == 'version.json' ||
    path == '.last_build_id';

void main() {
  final root = Directory(_buildDir);
  if (!root.existsSync()) {
    stderr.writeln('No existe $_buildDir — ejecuta antes `flutter build web`.');
    exit(1);
  }

  final files = <String>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    final path = entity.path.substring(root.path.length + 1).replaceAll('\\', '/');
    if (!_excluded(path)) files.add(path);
  }
  files.sort();

  // FNV-1a over every precached file's path and bytes (plus the engine
  // files, which are precached conditionally): cheap, dependency-free, and
  // changes whenever any of them does.
  var hash = 0x811c9dc5;
  void feed(List<int> bytes) {
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
  }

  var totalBytes = 0;
  for (final path in [...files, 'canvaskit/canvaskit.js', 'canvaskit/chromium/canvaskit.js']) {
    final file = File('$_buildDir/$path');
    if (!file.existsSync()) continue;
    feed(utf8.encode(path));
    final bytes = file.readAsBytesSync();
    feed(bytes);
    if (!path.startsWith('canvaskit/')) totalBytes += bytes.length;
  }
  final version = hash.toRadixString(16).padLeft(8, '0');

  final template = File('tool/sw_template.js').readAsStringSync();
  final output = template
      .replaceFirst('__VERSION__', version)
      .replaceFirst('__PRECACHE__', const JsonEncoder.withIndent('  ').convert(files));
  File('$_buildDir/sw.js').writeAsStringSync(output);

  stdout.writeln('sw.js $version: ${files.length} archivos '
      '(${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB + motor gráfico).');
}
