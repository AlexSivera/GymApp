import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme_mode.dart';

// Minimal, premium theming in the spirit of Whoop/Hevy: flat surfaces with
// a single vivid accent, borders instead of heavy shadows, and an explicit
// type scale so every screen reuses the same hierarchy instead of ad-hoc
// TextStyles. Five palettes (dark/light/pastel/pastel verde/pastel azul)
// share one ThemeData builder below — only the AppColors values change.
class AppTheme {
  AppTheme._();

  static const _dark = AppColors(
    accent: Color(0xFF5EEAD4),
    accentForeground: Color(0xFF06201C),
    background: Color(0xFF0A0C0E),
    surface: Color(0xFF15181B),
    surfaceRaised: Color(0xFF1C2024),
    border: Color(0xFF262B30),
    textColor: Color(0xFFF4F5F6),
    mutedTextColor: Color(0xFF9CA3AB),
    statusCompleted: Color(0xFF34D399),
    statusPlanned: Color(0xFFFBBF24),
    statusSkipped: Color(0xFFF87171),
    statusRest: Color(0xFF818CF8),
    statusEmpty: Color(0xFF3A3F45),
  );

  static const _light = AppColors(
    accent: Color(0xFF0F9C8E),
    accentForeground: Color(0xFFFFFFFF),
    background: Color(0xFFF7F8F9),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEFF1F3),
    border: Color(0xFFE1E4E8),
    textColor: Color(0xFF12161A),
    mutedTextColor: Color(0xFF64707A),
    statusCompleted: Color(0xFF0FA968),
    statusPlanned: Color(0xFFDB8B00),
    statusSkipped: Color(0xFFE5484D),
    statusRest: Color(0xFF5A67D8),
    statusEmpty: Color(0xFFD8DCE1),
  );

  static const _pastel = AppColors(
    accent: Color(0xFFD98BA7),
    accentForeground: Color(0xFF3A1626),
    background: Color(0xFFFBF3F0),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF7E9E3),
    border: Color(0xFFEEDCD3),
    textColor: Color(0xFF4A3B38),
    mutedTextColor: Color(0xFF9C8983),
    statusCompleted: Color(0xFF7FC29B),
    statusPlanned: Color(0xFFE8AD5F),
    statusSkipped: Color(0xFFE28080),
    statusRest: Color(0xFFA79BE8),
    statusEmpty: Color(0xFFE6D9D2),
  );

  static const _pastelGreen = AppColors(
    accent: Color(0xFF6FBE96),
    accentForeground: Color(0xFF0E2B1D),
    background: Color(0xFFF2FAF5),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE4F3EA),
    border: Color(0xFFD3E9DD),
    textColor: Color(0xFF2C3B32),
    mutedTextColor: Color(0xFF7C9186),
    statusCompleted: Color(0xFF4FAE7C),
    statusPlanned: Color(0xFFE0AC5A),
    statusSkipped: Color(0xFFE08080),
    statusRest: Color(0xFF8FB6DA),
    statusEmpty: Color(0xFFD9E7DF),
  );

  static const _pastelBlue = AppColors(
    accent: Color(0xFF6FA3D8),
    accentForeground: Color(0xFF0D2438),
    background: Color(0xFFF1F7FC),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFE3EFFA),
    border: Color(0xFFD2E3F3),
    textColor: Color(0xFF28384A),
    mutedTextColor: Color(0xFF7B8FA3),
    statusCompleted: Color(0xFF5FB98A),
    statusPlanned: Color(0xFFE0AC5A),
    statusSkipped: Color(0xFFE08080),
    statusRest: Color(0xFF5A85CC),
    statusEmpty: Color(0xFFDAE7F3),
  );

  static ThemeData get dark => _buildTheme(_dark, Brightness.dark);
  static ThemeData get light => _buildTheme(_light, Brightness.light);
  static ThemeData get pastel => _buildTheme(_pastel, Brightness.light);
  static ThemeData get pastelGreen => _buildTheme(_pastelGreen, Brightness.light);
  static ThemeData get pastelBlue => _buildTheme(_pastelBlue, Brightness.light);

  // Lets UI like the theme picker preview a palette without building (and
  // discarding) a full ThemeData for it.
  static AppColors colorsFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return _dark;
      case AppThemeMode.light:
        return _light;
      case AppThemeMode.pastel:
        return _pastel;
      case AppThemeMode.pastelGreen:
        return _pastelGreen;
      case AppThemeMode.pastelBlue:
        return _pastelBlue;
    }
  }

  static ThemeData themeFor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.light:
        return light;
      case AppThemeMode.pastel:
        return pastel;
      case AppThemeMode.pastelGreen:
        return pastelGreen;
      case AppThemeMode.pastelBlue:
        return pastelBlue;
    }
  }

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      surface: colors.surface,
    );

    // Display face: Outfit — a geometric sans with a confident, sporty
    // character for numbers and headings. Body face: Plus Jakarta Sans — warm
    // and highly legible at small sizes for stat-dense screens. The pairing
    // is what gives the app its own identity instead of the platform default.
    TextStyle display(TextStyle style) => GoogleFonts.outfit(textStyle: style);
    TextStyle body(TextStyle style) => GoogleFonts.plusJakartaSans(textStyle: style);

    final textTheme = TextTheme(
      // Hero numbers / big CTAs.
      displaySmall: display(TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colors.textColor,
        height: 1.1,
      )),
      headlineMedium: display(TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: colors.textColor,
      )),
      titleLarge: display(TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      )),
      titleMedium: display(TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.textColor,
      )),
      bodyLarge: body(TextStyle(fontSize: 16, color: colors.textColor, height: 1.35)),
      bodyMedium: body(TextStyle(fontSize: 14, color: colors.textColor, height: 1.35)),
      bodySmall: body(TextStyle(fontSize: 13, color: colors.mutedTextColor, height: 1.3)),
      labelLarge: body(TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textColor)),
      labelMedium: body(TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.mutedTextColor)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: colorScheme.copyWith(
        surface: colors.surface,
        surfaceContainerHighest: colors.surfaceRaised,
        onSurface: colors.textColor,
        outline: colors.border,
      ),
      extensions: [colors],
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: display(TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colors.textColor,
        )),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.mutedTextColor,
        textColor: colors.textColor,
      ),
      dividerTheme: DividerThemeData(color: colors.border, space: 1, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceRaised,
        selectedColor: colors.accent.withValues(alpha: 0.22),
        labelStyle: TextStyle(color: colors.textColor, fontWeight: FontWeight.w500),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.accentForeground,
          disabledBackgroundColor: colors.surfaceRaised,
          textStyle: display(const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textColor,
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accent.withValues(alpha: 0.18),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colors.textColor : colors.mutedTextColor,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        showDragHandle: true,
        dragHandleColor: colors.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceRaised,
        contentTextStyle: TextStyle(color: colors.textColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.accent),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: colors.surfaceRaised,
          selectedBackgroundColor: colors.accent.withValues(alpha: 0.22),
          side: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}
