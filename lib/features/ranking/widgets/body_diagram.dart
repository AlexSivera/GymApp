import 'package:flutter/material.dart';

// An original, hand-drawn human silhouette (not traced from any anatomical
// reference or licensed art) built entirely from vector curves. Front and
// back view, split into filled regions that light up per muscle group —
// same role as the old blocky-shapes version, just shaped like a body.
class BodyDiagram extends StatelessWidget {
  const BodyDiagram({super.key, required this.colorsByMuscle, required this.emptyColor});

  final Map<String, Color> colorsByMuscle;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.46,
            child: CustomPaint(
              painter: _BodyPainter(isBack: false, colorsByMuscle: colorsByMuscle, emptyColor: emptyColor),
            ),
          ),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.46,
            child: CustomPaint(
              painter: _BodyPainter(isBack: true, colorsByMuscle: colorsByMuscle, emptyColor: emptyColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({required this.isBack, required this.colorsByMuscle, required this.emptyColor});

  final bool isBack;
  final Map<String, Color> colorsByMuscle;
  final Color emptyColor;

  Color _colorFor(String muscle) => colorsByMuscle[muscle] ?? emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Virtual 220x480 canvas, scaled to fit whatever size we're given.
    canvas.save();
    final scale = size.width / 220;
    canvas.scale(scale, scale);

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

    void fill(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, outline);
    }

    final neutral = emptyColor.withValues(alpha: 0.5);

    // ---- Head + neck (never a trainable "muscle") ----
    final head = Path()..addOval(const Rect.fromLTWH(88, 8, 44, 50));
    fill(head, neutral);

    final neck = Path()
      ..moveTo(96, 50)
      ..lineTo(124, 50)
      ..cubicTo(127, 62, 131, 76, 136, 92)
      ..lineTo(84, 92)
      ..cubicTo(89, 76, 93, 62, 96, 50)
      ..close();
    fill(neck, neutral);

    // ---- Shoulders (deltoid caps) — inner edge tucks well under the neck
    // and torso, bottom tucks over the top of the upper arm, so no gap
    // shows between pieces.
    Path shoulderCap({required bool left}) {
      final sign = left ? -1.0 : 1.0;
      final innerX = 110 + sign * 14.0;
      final path = Path()..moveTo(innerX, 68);
      path.cubicTo(110 + sign * 34, 62, 110 + sign * 58, 68, 110 + sign * 64, 92);
      path.cubicTo(110 + sign * 68, 110, 110 + sign * 58, 126, 110 + sign * 44, 132);
      path.cubicTo(110 + sign * 36, 122, 110 + sign * 30, 108, 110 + sign * 24, 96);
      path.cubicTo(110 + sign * 20, 88, innerX, 78, innerX, 68);
      path.close();
      return path;
    }

    fill(shoulderCap(left: true), _colorFor('Hombros'));
    fill(shoulderCap(left: false), _colorFor('Hombros'));

    // ---- Torso ----
    if (isBack) {
      // Back: one lat-shaped region tapering from broad shoulders to a
      // narrow waist (no separate "back abs" muscle tracked).
      final back = Path()
        ..moveTo(70, 78)
        ..cubicTo(62, 100, 60, 128, 76, 158)
        ..cubicTo(84, 182, 86, 206, 88, 226)
        ..lineTo(132, 226)
        ..cubicTo(134, 206, 136, 182, 144, 158)
        ..cubicTo(160, 128, 158, 100, 150, 78)
        ..cubicTo(136, 94, 122, 102, 110, 102)
        ..cubicTo(98, 102, 84, 94, 70, 78)
        ..close();
      fill(back, _colorFor('Espalda'));
    } else {
      // Front: chest tapers into a narrower, separately-colored abdomen.
      final chest = Path()
        ..moveTo(72, 80)
        ..cubicTo(64, 100, 64, 122, 76, 138)
        ..cubicTo(88, 150, 100, 154, 110, 154)
        ..cubicTo(120, 154, 132, 150, 144, 138)
        ..cubicTo(156, 122, 156, 100, 148, 80)
        ..cubicTo(134, 96, 122, 104, 110, 104)
        ..cubicTo(98, 104, 86, 96, 72, 80)
        ..close();
      fill(chest, _colorFor('Pecho'));

      final abdomen = Path()
        ..moveTo(80, 140)
        ..cubicTo(84, 150, 92, 155, 110, 156)
        ..cubicTo(128, 155, 136, 150, 140, 140)
        ..cubicTo(138, 164, 137, 190, 134, 216)
        ..cubicTo(126, 225, 118, 230, 110, 230)
        ..cubicTo(102, 230, 94, 225, 86, 216)
        ..cubicTo(83, 190, 82, 164, 80, 140)
        ..close();
      fill(abdomen, _colorFor('Abdomen'));
    }

    // ---- Upper arms: biceps up front, triceps from the back ----
    Path upperArm({required bool left}) {
      final sign = left ? -1.0 : 1.0;
      final path = Path()..moveTo(110 + sign * 40, 106);
      path.cubicTo(110 + sign * 58, 116, 110 + sign * 68, 144, 110 + sign * 66, 170);
      path.cubicTo(110 + sign * 65, 188, 110 + sign * 60, 204, 110 + sign * 54, 216);
      path.cubicTo(110 + sign * 46, 210, 110 + sign * 40, 196, 110 + sign * 40, 176);
      path.cubicTo(110 + sign * 40, 152, 110 + sign * 40, 128, 110 + sign * 34, 112);
      path.close();
      return path;
    }

    final upperArmColor = _colorFor(isBack ? 'Tríceps' : 'Bíceps');
    fill(upperArm(left: true), upperArmColor);
    fill(upperArm(left: false), upperArmColor);

    // ---- Forearms: never a *primary* muscle in the exercise library ----
    Path forearm({required bool left}) {
      final sign = left ? -1.0 : 1.0;
      final path = Path()..moveTo(110 + sign * 56, 206);
      path.cubicTo(110 + sign * 62, 224, 110 + sign * 62, 246, 110 + sign * 56, 266);
      path.cubicTo(110 + sign * 51, 272, 110 + sign * 45, 272, 110 + sign * 41, 266);
      path.cubicTo(110 + sign * 38, 246, 110 + sign * 40, 224, 110 + sign * 44, 206);
      path.close();
      return path;
    }

    fill(forearm(left: true), neutral);
    fill(forearm(left: false), neutral);

    // ---- Hips / glutes — only meaningfully shown from the back ----
    if (isBack) {
      final glutes = Path()
        ..moveTo(84, 226)
        ..cubicTo(80, 244, 82, 260, 92, 270)
        ..cubicTo(100, 276, 120, 276, 128, 270)
        ..cubicTo(138, 260, 140, 244, 136, 226)
        ..close();
      fill(glutes, _colorFor('Glúteos'));
    }

    // ---- Thighs: quads up front, hamstrings from the back ----
    Path thigh({required bool left}) {
      final sign = left ? -1.0 : 1.0;
      final topY = isBack ? 250.0 : 222.0;
      final path = Path()..moveTo(110 + sign * 4, topY);
      path.cubicTo(110 + sign * 26, topY + 6, 110 + sign * 34, topY + 30, 110 + sign * 32, topY + 62);
      path.cubicTo(110 + sign * 31, topY + 82, 110 + sign * 27, topY + 100, 110 + sign * 22, topY + 112);
      path.cubicTo(110 + sign * 14, topY + 104, 110 + sign * 8, topY + 90, 110 + sign * 6, topY + 66);
      path.cubicTo(110 + sign * 5, topY + 40, 110 + sign * 4, topY + 18, 110 + sign * 3, topY + 4);
      path.close();
      return path;
    }

    final thighColor = _colorFor(isBack ? 'Isquiotibiales' : 'Cuádriceps');
    fill(thigh(left: true), thighColor);
    fill(thigh(left: false), thighColor);

    // ---- Calves — shown on both views ----
    Path calf({required bool left}) {
      final sign = left ? -1.0 : 1.0;
      final topY = isBack ? 352.0 : 324.0;
      final path = Path()..moveTo(110 + sign * 20, topY);
      path.cubicTo(110 + sign * 30, topY + 10, 110 + sign * 30, topY + 34, 110 + sign * 24, topY + 56);
      path.cubicTo(110 + sign * 20, topY + 68, 110 + sign * 14, topY + 70, 110 + sign * 10, topY + 62);
      path.cubicTo(110 + sign * 6, topY + 40, 110 + sign * 8, topY + 16, 110 + sign * 12, topY + 2);
      path.close();
      return path;
    }

    final calfColor = _colorFor('Gemelos');
    fill(calf(left: true), calfColor);
    fill(calf(left: false), calfColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) =>
      oldDelegate.colorsByMuscle != colorsByMuscle || oldDelegate.emptyColor != emptyColor;
}
