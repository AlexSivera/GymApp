import 'package:flutter/material.dart';

/// The palette behind the active [AppThemeMode], exposed as a ThemeExtension
/// so every widget can read the *current* theme's colors instead of a
/// hardcoded static constant — this is what makes theme switching actually
/// repaint the whole app, not just Scaffold backgrounds.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.accentForeground,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.textColor,
    required this.mutedTextColor,
    required this.statusCompleted,
    required this.statusPlanned,
    required this.statusSkipped,
    required this.statusRest,
    required this.statusEmpty,
  });

  final Color accent;
  final Color accentForeground;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color textColor;
  final Color mutedTextColor;
  final Color statusCompleted;
  final Color statusPlanned;
  final Color statusSkipped;
  final Color statusRest;
  final Color statusEmpty;

  Color get statusToday => accent;

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  @override
  AppColors copyWith({
    Color? accent,
    Color? accentForeground,
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? textColor,
    Color? mutedTextColor,
    Color? statusCompleted,
    Color? statusPlanned,
    Color? statusSkipped,
    Color? statusRest,
    Color? statusEmpty,
  }) {
    return AppColors(
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      textColor: textColor ?? this.textColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
      statusCompleted: statusCompleted ?? this.statusCompleted,
      statusPlanned: statusPlanned ?? this.statusPlanned,
      statusSkipped: statusSkipped ?? this.statusSkipped,
      statusRest: statusRest ?? this.statusRest,
      statusEmpty: statusEmpty ?? this.statusEmpty,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      mutedTextColor: Color.lerp(mutedTextColor, other.mutedTextColor, t)!,
      statusCompleted: Color.lerp(statusCompleted, other.statusCompleted, t)!,
      statusPlanned: Color.lerp(statusPlanned, other.statusPlanned, t)!,
      statusSkipped: Color.lerp(statusSkipped, other.statusSkipped, t)!,
      statusRest: Color.lerp(statusRest, other.statusRest, t)!,
      statusEmpty: Color.lerp(statusEmpty, other.statusEmpty, t)!,
    );
  }
}
