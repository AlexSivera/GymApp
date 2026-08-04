import 'package:flutter/animation.dart';

// Consistent animation timings so every card/state transition in the app
// feels like the same product instead of default per-widget durations.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve curve = Curves.easeOutCubic;
}
