import 'package:flutter/material.dart';

// GymZ's own colors on top of AppColors: the ki/aura hues and the few
// Dragon Ball materials (esferas, semilla, rastreador) that have no generic
// AppColors role. Static on purpose — GymZ has a single look, there's no
// theme switching for these to follow.
class ZColors {
  ZColors._();

  static const night = Color(0xFF0A0D1C);
  static const panel = Color(0xFF171E46);
  static const panelRaised = Color(0xFF1E2757);
  static const line = Color(0xFF283062);
  static const ink = Color(0xFFF5F1E6);
  static const muted = Color(0xFFA3A9CB);

  static const gi = Color(0xFFFF6A13);
  static const giDeep = Color(0xFFC24400);
  static const gold = Color(0xFFFFD23F);
  static const kiBlue = Color(0xFF3CC8FF);
  static const scouter = Color(0xFF45FF8E);
  static const kaioken = Color(0xFFFF3D45);
  static const senzu = Color(0xFF7FCB4B);
  static const namek = Color(0xFF7BE3A8);
  static const silver = Color(0xFFE6ECF7);
  static const whiteKi = Color(0xFFF2F6FF);

  static const ballHighlight = Color(0xFFFFF2B8);
  static const ball = Color(0xFFFFA21A);
  static const ballShade = Color(0xFFD86200);
  static const ballStar = Color(0xFFD6211A);

  static const mangaPaper = Color(0xFFFFF8E8);
  static const mangaInk = Color(0xFF131427);
}

// Font families declared in pubspec.yaml.
class ZFonts {
  ZFonts._();

  // Heavy display face with kanji support — titles, big numbers, stamps.
  static const display = 'DelaGothicOne';
  // Scouter read-outs: timers, power levels, labels.
  static const hud = 'ShareTechMono';
}

// "GymZ" text styles that aren't part of the Material TextTheme.
class ZText {
  ZText._();

  static TextStyle hud({double size = 12, Color color = ZColors.scouter, double spacing = 1.2}) => TextStyle(
        fontFamily: ZFonts.hud,
        fontSize: size,
        color: color,
        letterSpacing: spacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle display({double size = 28, Color color = ZColors.ink, double height = 1.05}) => TextStyle(
        fontFamily: ZFonts.display,
        fontSize: size,
        color: color,
        height: height,
      );
}
