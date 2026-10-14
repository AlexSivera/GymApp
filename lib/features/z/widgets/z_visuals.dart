import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/z_palette.dart';
import 'z_media.dart';

// One of the seven dragon balls: an orange glass sphere with [stars] red
// stars, or a dim empty socket when not [lit].
class DragonBall extends StatelessWidget {
  const DragonBall({super.key, required this.stars, this.lit = true, this.size = 32, this.glow = false});

  final int stars;
  final bool lit;
  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _DragonBallPainter(stars: stars, lit: lit, glow: glow)),
    );
  }
}

class _DragonBallPainter extends CustomPainter {
  _DragonBallPainter({required this.stars, required this.lit, required this.glow});

  final int stars;
  final bool lit;
  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: c, radius: r);

    if (lit && glow) {
      canvas.drawCircle(
        c,
        r * 1.05,
        Paint()
          ..color = ZColors.ball.withValues(alpha: 0.7)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.45),
      );
    }

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.42),
          colors: lit
              ? const [ZColors.ballHighlight, Color(0xFFFFC94A), ZColors.ball, ZColors.ballShade]
              : const [Color(0xFF3A4170), Color(0xFF262D58), Color(0xFF1C2248), Color(0xFF161B3B)],
          stops: const [0.0, 0.2, 0.55, 1.0],
        ).createShader(rect),
    );

    if (stars > 0) {
      final starPaint = Paint()..color = lit ? ZColors.ballStar : const Color(0xFF4A5288);
      final starR = r * (stars == 1 ? 0.34 : stars <= 3 ? 0.24 : 0.19);
      for (final offset in _starLayout(stars)) {
        _drawStar(canvas, c + offset * r * 0.42, starR, starPaint);
      }
    }

    // Glass highlight.
    if (lit) {
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(-r * 0.32, -r * 0.45), width: r * 0.55, height: r * 0.3),
        Paint()..color = Colors.white.withValues(alpha: 0.45),
      );
    }
  }

  List<Offset> _starLayout(int n) {
    switch (n) {
      case 1:
        return const [Offset.zero];
      case 2:
        return const [Offset(-0.6, 0), Offset(0.6, 0)];
      case 3:
        return const [Offset(0, -0.6), Offset(-0.6, 0.45), Offset(0.6, 0.45)];
      case 4:
        return const [Offset(-0.55, -0.55), Offset(0.55, -0.55), Offset(-0.55, 0.55), Offset(0.55, 0.55)];
      default:
        final points = <Offset>[if (n == 5 || n == 7) Offset.zero];
        final ring = n == 6 ? 6 : n - 1;
        for (var i = 0; i < ring; i++) {
          final a = -math.pi / 2 + 2 * math.pi * i / ring;
          points.add(Offset(math.cos(a), math.sin(a)) * 0.82);
        }
        return points;
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + math.pi * i / 5;
      final rr = i.isEven ? radius : radius * 0.45;
      final p = center + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(covariant _DragonBallPainter old) =>
      old.stars != stars || old.lit != lit || old.glow != glow;
}

// A flickering ki aura rising behind [child] (a flame-shaped glow). Static
// when the user asked to reduce motion.
class KiAura extends StatefulWidget {
  const KiAura({super.key, required this.color, required this.child, this.intensity = 1, this.spread = 1.4});

  final Color color;
  final Widget child;
  // 0..1+ — grade of the transformation; scales height and brightness.
  final double intensity;
  // How far the aura extends past the child, as a factor of its size.
  final double spread;

  @override
  State<KiAura> createState() => _KiAuraState();
}

class _KiAuraState extends State<KiAura> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Paints past its own bounds on purpose (the flame rises above and
        // spreads beside the child); nothing up the tree clips it.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _AuraPainter(
                  color: widget.color,
                  t: Curves.easeInOut.transform(_controller.value),
                  intensity: widget.intensity,
                  spread: widget.spread,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuraPainter extends CustomPainter {
  _AuraPainter({required this.color, required this.t, required this.intensity, required this.spread});

  final Color color;
  final double t;
  final double intensity;
  final double spread;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * spread;
    final h = size.height * (1 + 0.45 * intensity) * (0.94 + 0.12 * t);
    final base = Offset(size.width / 2, size.height + size.height * 0.04);

    Path flame(double width, double height, double wobble) {
      final left = base.dx - width / 2;
      final path = Path()..moveTo(left, base.dy);
      const tips = [0.0, 0.12, 0.26, 0.4, 0.5, 0.6, 0.74, 0.88, 1.0];
      const heights = [0.45, 0.72, 0.6, 0.9, 1.0, 0.88, 0.62, 0.74, 0.45];
      for (var i = 0; i < tips.length; i++) {
        final x = left + width * tips[i];
        final jitter = math.sin((t * 2 * math.pi) + i * 1.7) * wobble;
        final y = base.dy - (height * heights[i]) + jitter;
        if (i == 0) {
          path.lineTo(x, y);
        } else {
          final prevX = left + width * tips[i - 1];
          path.quadraticBezierTo((prevX + x) / 2, y + height * 0.18, x, y);
        }
      }
      path
        ..lineTo(left + width, base.dy)
        ..close();
      return path;
    }

    final outer = flame(w, h, h * 0.04);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color.withValues(alpha: 0.75), color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.06),
    );
    final inner = flame(w * 0.7, h * 0.8, h * 0.03);
    canvas.drawPath(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.white.withValues(alpha: 0.55 * (0.6 + 0.4 * intensity.clamp(0, 1))), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.04),
    );
  }

  @override
  bool shouldRepaint(covariant _AuraPainter old) =>
      old.t != t || old.color != color || old.intensity != intensity || old.spread != spread;
}

// Manga focus lines radiating from [focus] (fractional position), clear in
// the middle. For impact moments only.
class SpeedLines extends StatelessWidget {
  const SpeedLines({super.key, this.color = Colors.white, this.focus = const Alignment(0, -0.3), this.opacity = 0.35});

  final Color color;
  final Alignment focus;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _SpeedLinesPainter(color: color.withValues(alpha: opacity), focus: focus),
        size: Size.infinite,
      ),
    );
  }
}

class _SpeedLinesPainter extends CustomPainter {
  _SpeedLinesPainter({required this.color, required this.focus});

  final Color color;
  final Alignment focus;

  @override
  void paint(Canvas canvas, Size size) {
    final center = focus.alongSize(size);
    final far = size.longestSide * 1.2;
    final rnd = math.Random(7);
    final paint = Paint()..color = color;
    const count = 90;
    for (var i = 0; i < count; i++) {
      final a = 2 * math.pi * i / count + rnd.nextDouble() * 0.03;
      final spread = 0.004 + rnd.nextDouble() * 0.012;
      final start = size.shortestSide * (0.28 + rnd.nextDouble() * 0.22);
      final path = Path()
        ..moveTo(center.dx + math.cos(a) * start, center.dy + math.sin(a) * start)
        ..lineTo(center.dx + math.cos(a - spread) * far, center.dy + math.sin(a - spread) * far)
        ..lineTo(center.dx + math.cos(a + spread) * far, center.dy + math.sin(a + spread) * far)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedLinesPainter old) => old.color != color || old.focus != focus;
}

// Kaio-sama's face: the pack portrait when there is one, otherwise a blue
// orb with 界.
class KaioAvatar extends StatelessWidget {
  const KaioAvatar({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final orb = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(center: Alignment(-0.3, -0.35), colors: [Color(0xFF6FA5FF), Color(0xFF2B5BC4)]),
      ),
      alignment: Alignment.center,
      child: Text('界', style: ZText.display(size: size * 0.45)),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(child: ZImage('kaio', fallback: orb)),
    );
  }
}

// The dragon radar behind the calendar: faint green rings and a slow
// sweep. Static with "reduce motion".
class RadarBackdrop extends StatefulWidget {
  const RadarBackdrop({super.key});

  @override
  State<RadarBackdrop> createState() => _RadarBackdropState();
}

class _RadarBackdropState extends State<RadarBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep =
      AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _sweep.stop();
    } else if (!_sweep.isAnimating) {
      _sweep.repeat();
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) => CustomPaint(painter: _RadarPainter(_sweep.value)),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.longestSide * 0.62;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = ZColors.scouter.withValues(alpha: 0.10);
    for (var r = 34.0; r < radius; r += 34) {
      canvas.drawCircle(center, r, ring);
    }
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), ring);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), ring);

    final angle = t * 2 * math.pi;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: 2 * math.pi,
          colors: [ZColors.scouter.withValues(alpha: 0), ZColors.scouter.withValues(alpha: 0.14)],
          stops: const [0.8, 1],
          transform: GradientRotation(angle),
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.t != t;
}

// The scouter's green read-out frame (top-right corner cut big, like the
// lens).
class ScouterFrame extends StatelessWidget {
  const ScouterFrame({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(36),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ZColors.scouter.withValues(alpha: 0.16), ZColors.scouter.withValues(alpha: 0.04)],
        ),
        border: Border.all(color: ZColors.scouter.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [BoxShadow(color: ZColors.scouter.withValues(alpha: 0.12), blurRadius: 18)],
      ),
      child: child,
    );
  }
}
