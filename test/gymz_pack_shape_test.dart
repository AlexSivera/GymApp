import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/features/z/widgets/campaign_widgets.dart';
import 'package:gymapp/services/z/media_pack.dart';

// A 100x200 PNG: a figure (head + body) on a transparent background, or the
// same over a solid backdrop (a screen capture).
Future<List<int>> _figurePng({required bool backdrop}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (backdrop) canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 200), Paint()..color = Colors.blue);
  final paint = Paint()..color = Colors.orange;
  canvas.drawCircle(const Offset(50, 30), 15, paint);
  canvas.drawRect(const Rect.fromLTRB(30, 45, 70, 190), paint);
  final image = await recorder.endRecording().toImage(100, 200);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('a cut-out is detected and its face found; a capture is not a cut-out', (tester) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('gymz_pack_test');
      await File('${dir.path}/maestro_roshi_contento.png').writeAsBytes(await _figurePng(backdrop: false));
      await File('${dir.path}/maestro_krilin_contento.png').writeAsBytes(await _figurePng(backdrop: true));
      await MediaPack.initWithDirectory(dir);

      final cutout = await packImageShape('maestro_roshi_contento');
      expect(cutout.cutout, isTrue);
      final face = cutout.face!;
      expect(face.contains(const Offset(0.5, 0.15)), isTrue, reason: 'the head centre is inside the face square: $face');
      expect(face.center.dx, closeTo(0.5, 0.05));

      final capture = await packImageShape('maestro_krilin_contento');
      expect(capture.cutout, isFalse);
      expect(capture.face, isNull);

      await dir.delete(recursive: true);
    });
  });
}
