import 'package:flutter/material.dart';

import 'body_masks.dart';

enum BodyThumbnailShape { circle, hexagon }

// A small framed crop of the body illustration with some muscles
// highlighted — the per-muscle / per-group icon of the Rangos list.
class BodyThumbnail extends StatelessWidget {
  const BodyThumbnail({
    super.key,
    required this.frame,
    required this.colorsByMuscle,
    this.size = 56,
    this.shape = BodyThumbnailShape.circle,
    this.borderColor,
  });

  final BodyFrame frame;

  // Muscles to highlight and their color; muscles not listed stay dark.
  final Map<String, Color> colorsByMuscle;
  final double size;
  final BodyThumbnailShape shape;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final crop = frame.crop;
    final scale = size / crop.width;
    final image = SizedBox.square(
      dimension: size,
      child: ColoredBox(
        color: bodyBackgroundColor,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: -crop.left * scale,
              top: -crop.top * scale,
              width: bodyImageSize.width * scale,
              height: bodyImageSize.height * scale,
              child: BodyLayers(view: frame.view, tints: maskTints(frame.view, colorsByMuscle)),
            ),
          ],
        ),
      ),
    );

    final outline = borderColor ?? Colors.white.withValues(alpha: 0.12);
    return switch (shape) {
      BodyThumbnailShape.circle => DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: outline, width: 2)),
          child: ClipOval(child: image),
        ),
      BodyThumbnailShape.hexagon => CustomPaint(
          foregroundPainter: _HexagonBorderPainter(outline),
          child: ClipPath(clipper: _HexagonClipper(), child: image),
        ),
    };
  }
}

// Same pointy-top hexagon as RankBadge.
Path _hexagon(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w * 0.5, 0)
    ..lineTo(w, h * 0.25)
    ..lineTo(w, h * 0.75)
    ..lineTo(w * 0.5, h)
    ..lineTo(0, h * 0.75)
    ..lineTo(0, h * 0.25)
    ..close();
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _hexagon(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HexagonBorderPainter extends CustomPainter {
  _HexagonBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _hexagon(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HexagonBorderPainter oldDelegate) => oldDelegate.color != color;
}
