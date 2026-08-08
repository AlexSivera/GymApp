import 'package:flutter/material.dart';

import '../../../services/ranking_engine/rank_tier.dart';

const rankTierColors = <RankTier, Color>{
  RankTier.hierro: Color(0xFF8D8D93),
  RankTier.bronce: Color(0xFFB2703B),
  RankTier.plata: Color(0xFFC7CBD1),
  RankTier.oro: Color(0xFFE7B93A),
  RankTier.platino: Color(0xFF7FD9CE),
  RankTier.esmeralda: Color(0xFF34D399),
  RankTier.diamante: Color(0xFF5EC8F2),
  RankTier.maestro: Color(0xFFC77DFF),
};

// Hexagonal badge for a Rank — a single consistent shape, colored by tier,
// with the I/II/III sub-step in the middle.
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
        painter: _HexagonPainter(color: color),
        child: Center(
          child: Text(
            const ['', 'I', 'II', 'III'][rank.subTier],
            style: TextStyle(fontSize: size * 0.32, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  _HexagonPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) => oldDelegate.color != color;
}
