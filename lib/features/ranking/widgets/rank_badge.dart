import 'package:flutter/material.dart';

import '../../../services/ranking_engine/rank_tier.dart';

// Aura color of each transformation.
const rankTierColors = <RankTier, Color>{
  RankTier.hierro: Color(0xFFC9CFE6),
  RankTier.bronce: Color(0xFFF2F6FF),
  RankTier.plata: Color(0xFFFF3D45),
  RankTier.oro: Color(0xFFFFD23F),
  RankTier.platino: Color(0xFFFFE066),
  RankTier.esmeralda: Color(0xFFFFB81F),
  RankTier.diamante: Color(0xFF3CC8FF),
  RankTier.maestro: Color(0xFFE6ECF7),
};

// A ki orb for a Rank: a dark core ringed by its transformation's aura,
// glowing harder with each grade, with the grade (I/II/III, or ×2… for
// Kaioken) in the middle.
class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank, this.size = 40});

  final Rank rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = rankTierColors[rank.tier]!;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KiOrbPainter(color: color, intensity: rank.subTier / 3),
        child: Center(
          child: Text(
            rankGradeLabel(rank.tier, rank.subTier),
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.w800,
              color: color,
              shadows: [Shadow(color: color, blurRadius: size * 0.2)],
            ),
          ),
        ),
      ),
    );
  }
}

class _KiOrbPainter extends CustomPainter {
  _KiOrbPainter({required this.color, required this.intensity});
  final Color color;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.25 + 0.3 * intensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * (0.18 + 0.2 * intensity)),
    );
    canvas.drawCircle(
      center,
      radius * 0.84,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF0A0D1C), Color.lerp(const Color(0xFF0A0D1C), color, 0.28)!],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.84)),
    );
    canvas.drawCircle(
      center,
      radius * 0.84,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.1,
    );
  }

  @override
  bool shouldRepaint(covariant _KiOrbPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.intensity != intensity;
}
