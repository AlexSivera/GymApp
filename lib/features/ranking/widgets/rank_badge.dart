import 'package:flutter/material.dart';

import '../../../services/ranking_engine/rank_tier.dart';

// Aura color of each transformation.
const rankTierColors = <RankTier, Color>{
  RankTier.hierro: Color(0xFFB07444), // Saiyan: marrón tierra
  RankTier.bronce: Color(0xFFFFC93C), // SSJ: dorado clásico
  RankTier.plata: Color(0xFFFFF35C), // SSJ2: oro eléctrico
  RankTier.oro: Color(0xFFE89A0C), // SSJ3: ámbar intenso
  RankTier.platino: Color(0xFFC02A3E), // SSJ4: granate
  RankTier.esmeralda: Color(0xFFFF3D5A), // SSJ God: rojo brillante
  RankTier.diamante: Color(0xFF2EB8FF), // SSJ Blue
  RankTier.maestro: Color(0xFFF4F6FF), // Ultra Instinto: blanco brillante
};

// A ki orb for a Rank: a dark core ringed by its transformation's aura,
// glowing harder with each grade, with the grade's stars in the middle.
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
