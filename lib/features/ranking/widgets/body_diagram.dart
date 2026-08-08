import 'package:flutter/material.dart';

// A deliberately simple, original silhouette — not an anatomical
// illustration. Big blocky regions (torso, shoulders, arms, legs) colored
// per muscle group, front and back, in the same spirit as the reference
// but built entirely from basic shapes instead of licensed muscle art.
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
            aspectRatio: 0.5,
            child: CustomPaint(
              painter: _BodyPainter(isBack: false, colorsByMuscle: colorsByMuscle, emptyColor: emptyColor),
            ),
          ),
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.5,
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
    // Virtual 200x400 canvas, scaled to fit whatever size we're given.
    canvas.save();
    final scale = size.width / 200;
    canvas.scale(scale, scale);

    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    void region(Rect rect, Color color, {double radius = 10}) {
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(rrect, Paint()..color = color);
      canvas.drawRRect(rrect, outline);
    }

    void capsule(Rect rect, Color color) => region(rect, color, radius: rect.width / 2);

    // Head + neck — always neutral, not a trainable "muscle".
    canvas.drawCircle(const Offset(100, 28), 22, Paint()..color = emptyColor.withValues(alpha: 0.5));
    canvas.drawCircle(const Offset(100, 28), 22, outline);
    region(const Rect.fromLTWH(90, 46, 20, 18), emptyColor.withValues(alpha: 0.5), radius: 6);

    // Shoulders (both views).
    region(const Rect.fromLTWH(28, 72, 36, 30), _colorFor('Hombros'));
    region(const Rect.fromLTWH(136, 72, 36, 30), _colorFor('Hombros'));

    // Torso: front splits into Pecho (upper) / Abdomen (lower); back is a
    // single Espalda region (no back-of-abs muscle tracked).
    if (isBack) {
      region(const Rect.fromLTWH(60, 68, 80, 150), _colorFor('Espalda'));
    } else {
      region(const Rect.fromLTWH(60, 68, 80, 78), _colorFor('Pecho'));
      region(const Rect.fromLTWH(60, 150, 80, 68), _colorFor('Abdomen'));
    }

    // Upper arms: Bíceps up front, Tríceps from the back.
    final upperArmColor = _colorFor(isBack ? 'Tríceps' : 'Bíceps');
    capsule(const Rect.fromLTWH(24, 98, 26, 80), upperArmColor);
    capsule(const Rect.fromLTWH(150, 98, 26, 80), upperArmColor);

    // Forearms aren't individually ranked (never a *primary* muscle in the
    // exercise library) — always neutral.
    final forearmColor = emptyColor.withValues(alpha: 0.5);
    capsule(const Rect.fromLTWH(26, 180, 22, 62), forearmColor);
    capsule(const Rect.fromLTWH(152, 180, 22, 62), forearmColor);

    // Hips/glutes — only meaningfully shown from the back.
    if (isBack) {
      region(const Rect.fromLTWH(66, 214, 68, 34), _colorFor('Glúteos'));
    }

    // Thighs: Cuádriceps up front, Isquiotibiales from the back.
    final thighColor = _colorFor(isBack ? 'Isquiotibiales' : 'Cuádriceps');
    capsule(const Rect.fromLTWH(64, 244, 32, 88), thighColor);
    capsule(const Rect.fromLTWH(104, 244, 32, 88), thighColor);

    // Calves — shown on both views.
    final calfColor = _colorFor('Gemelos');
    capsule(const Rect.fromLTWH(67, 336, 26, 56), calfColor);
    capsule(const Rect.fromLTWH(107, 336, 26, 56), calfColor);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) =>
      oldDelegate.colorsByMuscle != colorsByMuscle || oldDelegate.emptyColor != emptyColor;
}
