import 'package:flutter/material.dart';

import 'app_spacing.dart';

// Dark, minimal, premium theme in the spirit of Whoop/Hevy: near-black
// surfaces with a warm-neutral tint (not pure grey), a single vivid accent,
// borders instead of heavy shadows, and an explicit type scale so every
// screen reuses the same hierarchy instead of ad-hoc TextStyles.
class AppTheme {
  AppTheme._();

  static const accent = Color(0xFF5EEAD4);
  static const background = Color(0xFF0A0C0E);
  static const surface = Color(0xFF15181B);
  static const surfaceRaised = Color(0xFF1C2024);
  static const border = Color(0xFF262B30);

  // Status colors used by the calendar, workout checklist and stat badges —
  // kept as named statics so every screen references the same palette.
  static const statusCompleted = Color(0xFF34D399);
  static const statusPlanned = Color(0xFFFBBF24);
  static const statusSkipped = Color(0xFFF87171);
  static const statusRest = Color(0xFF818CF8);
  static const statusEmpty = Color(0xFF3A3F45);
  static const statusToday = accent;

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );

    const textColor = Color(0xFFF4F5F6);
    const mutedTextColor = Color(0xFF9CA3AB);

    final textTheme = TextTheme(
      // Hero numbers / big CTAs.
      displaySmall: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textColor,
        height: 1.1,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textColor,
      ),
      titleLarge: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: const TextStyle(fontSize: 16, color: textColor, height: 1.35),
      bodyMedium: const TextStyle(fontSize: 14, color: textColor, height: 1.35),
      bodySmall: TextStyle(fontSize: 13, color: mutedTextColor, height: 1.3),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mutedTextColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme.copyWith(
        surface: surface,
        surfaceContainerHighest: surfaceRaised,
        onSurface: textColor,
        outline: border,
      ),
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: border),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: mutedTextColor,
        textColor: textColor,
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        selectedColor: accent.withValues(alpha: 0.22),
        labelStyle: const TextStyle(color: textColor, fontWeight: FontWeight.w500),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF06201C),
          disabledBackgroundColor: surfaceRaised,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.18),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? textColor : mutedTextColor,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceRaised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: const TextStyle(color: textColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: surfaceRaised,
          selectedBackgroundColor: accent.withValues(alpha: 0.22),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}
