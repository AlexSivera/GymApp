import 'package:flutter/material.dart';

// Shared rounded, padded card used across dashboard-style sections.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.color, this.borderColor});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  // Overrides the theme's default grey border — used sparingly to give a
  // card more visual weight (e.g. today's hero card) without introducing a
  // one-off shape everywhere it's needed.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      shape: borderColor == null
          ? null
          : RoundedRectangleBorder(
              borderRadius: (Theme.of(context).cardTheme.shape as RoundedRectangleBorder?)
                      ?.borderRadius ??
                  BorderRadius.zero,
              side: BorderSide(color: borderColor!, width: 1.5),
            ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}
