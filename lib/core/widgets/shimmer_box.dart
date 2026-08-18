import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

// A gently animated rounded rectangle standing in for a card while its data
// loads — sized to roughly match the real content so the page doesn't pop or
// jump once data arrives, instead of a spinner that gives no sense of shape.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({super.key, this.height = 96, this.borderRadius});

  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final colors = AppColors.of(context);
        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(AppRadius.md),
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: colors.border),
              gradient: LinearGradient(
                begin: Alignment(-1 + 3 * t, 0),
                end: Alignment(1 + 3 * t, 0),
                colors: [colors.surface, colors.surfaceRaised, colors.surface],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
          ),
        );
      },
    );
  }
}
