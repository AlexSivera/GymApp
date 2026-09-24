import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

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

  // Families declared in pubspec.yaml (bundled TTFs, no runtime download).
  static const displayFont = 'Outfit';
  static const bodyFont = 'PlusJakartaSans';

  static ThemeData _buildTheme(AppColors colors, Brightness brightness) {
    // The seed only fills in the roles the app never sets explicitly; every
    // role a stock widget actually paints with (primary for FilledButton,
    // FAB, Switch, progress bars, focused fields…) is pinned to the palette
    // below, so no widget falls back to a seed-derived teal that doesn't
    // match the accent.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
    ).copyWith(
      primary: colors.accent,
      onPrimary: colors.accentForeground,
      primaryContainer: colors.accent,
      onPrimaryContainer: colors.accentForeground,
      secondary: colors.accent,
      onSecondary: colors.accentForeground,
      secondaryContainer: colors.accent.withValues(alpha: 0.22),
      onSecondaryContainer: colors.textColor,
      error: colors.statusSkipped,
      surface: colors.surface,
      onSurface: colors.textColor,
      onSurfaceVariant: colors.mutedTextColor,
      surfaceContainerLowest: colors.background,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surfaceRaised,
      surfaceContainerHighest: colors.surfaceRaised,
      outline: colors.border,
      outlineVariant: colors.border,
      surfaceTint: Colors.transparent,
    );

    // Display face: Outfit — a geometric sans with a confident, sporty
    // character for numbers and headings. Body face: Plus Jakarta Sans — warm
    // and highly legible at small sizes for stat-dense screens. Every slot of
    // the TextTheme is filled (not just the ones the screens use directly):
    // stock widgets like dialog titles, chips, menus and tooltips read the
    // other slots, and an unset one silently fell back to Roboto.
    TextStyle display(double size, FontWeight weight, {double? spacing, double? height}) => TextStyle(
          fontFamily: displayFont,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          height: height,
          color: colors.textColor,
        );
    TextStyle body(double size, {FontWeight weight = FontWeight.w400, Color? color, double? height}) =>
        TextStyle(
          fontFamily: bodyFont,
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: color ?? colors.textColor,
        );

    final textTheme = TextTheme(
      displayLarge: display(48, FontWeight.w700, spacing: -1, height: 1.05),
      displayMedium: display(40, FontWeight.w700, spacing: -0.8, height: 1.05),
      // Hero numbers / big CTAs.
      displaySmall: display(34, FontWeight.w700, spacing: -0.5, height: 1.1),
      headlineLarge: display(28, FontWeight.w700, spacing: -0.4),
      headlineMedium: display(24, FontWeight.w700, spacing: -0.3),
      headlineSmall: display(21, FontWeight.w700, spacing: -0.2),
      titleLarge: display(19, FontWeight.w600),
      titleMedium: display(16, FontWeight.w600),
      titleSmall: display(14, FontWeight.w600),
      bodyLarge: body(16, height: 1.35),
      bodyMedium: body(14, height: 1.35),
      bodySmall: body(13, color: colors.mutedTextColor, height: 1.3),
      labelLarge: body(14, weight: FontWeight.w600),
      labelMedium: body(12, weight: FontWeight.w600, color: colors.mutedTextColor),
      labelSmall: body(11, weight: FontWeight.w600, color: colors.mutedTextColor),
    );

    final shortButtonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      // Anything that builds a TextStyle from scratch (no theme slot) still
      // gets the brand face instead of the platform default.
      fontFamily: bodyFont,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      colorScheme: colorScheme,
      extensions: [colors],
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      // A soft, low-contrast hover/press tint — the stock one read as a grey
      // slab on the dark palette.
      hoverColor: colors.textColor.withValues(alpha: 0.04),
      highlightColor: colors.textColor.withValues(alpha: 0.05),
      splashColor: colors.accent.withValues(alpha: 0.12),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          // One consistent, calm transition on every platform (the web build
          // otherwise picks a per-browser default).
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: colors.textColor,
        titleTextStyle: display(20, FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        // Clips ink (hover/press highlights) to the rounded corners — without
        // it the highlight of a tappable row spilled out past the card edge.
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.mutedTextColor,
        textColor: colors.textColor,
        titleTextStyle: body(15, weight: FontWeight.w600),
        subtitleTextStyle: body(13, color: colors.mutedTextColor, height: 1.3),
      ),
      dividerTheme: DividerThemeData(color: colors.border, space: 1, thickness: 1),
      iconTheme: IconThemeData(color: colors.textColor),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceRaised,
        selectedColor: colors.accent.withValues(alpha: 0.22),
        checkmarkColor: colors.textColor,
        labelStyle: body(13, weight: FontWeight.w600),
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.accentForeground,
          disabledBackgroundColor: colors.surfaceRaised,
          disabledForegroundColor: colors.mutedTextColor,
          textStyle: display(16, FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.xl),
          shape: shortButtonShape,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.accentForeground,
          disabledBackgroundColor: colors.surfaceRaised,
          disabledForegroundColor: colors.mutedTextColor,
          textStyle: display(15, FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: shortButtonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textColor,
          textStyle: body(14, weight: FontWeight.w600),
          side: BorderSide(color: colors.border),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
          shape: shortButtonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.accent,
          textStyle: body(14, weight: FontWeight.w700),
          shape: shortButtonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: colors.textColor),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.accent,
        foregroundColor: colors.accentForeground,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        extendedTextStyle: display(15, FontWeight.w700),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return colors.border;
          return states.contains(WidgetState.selected) ? colors.accentForeground : colors.mutedTextColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return colors.surfaceRaised;
          return states.contains(WidgetState.selected) ? colors.accent : colors.surfaceRaised;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? Colors.transparent : colors.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? colors.accent : Colors.transparent),
        checkColor: WidgetStatePropertyAll(colors.accentForeground),
        side: BorderSide(color: colors.mutedTextColor, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? colors.accent : colors.mutedTextColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceRaised,
        hintStyle: body(15, color: colors.mutedTextColor),
        labelStyle: body(15, color: colors.mutedTextColor),
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
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.accent.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? colors.textColor : colors.mutedTextColor,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return body(
            11,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colors.textColor : colors.mutedTextColor,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colors.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: display(20, FontWeight.w700),
        contentTextStyle: body(14, color: colors.mutedTextColor, height: 1.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        textStyle: body(14, weight: FontWeight.w500),
        labelTextStyle: WidgetStatePropertyAll(body(14, weight: FontWeight.w500)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: colors.border),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(colors.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.textColor.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: body(12, weight: FontWeight.w600, color: colors.background),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceRaised,
        contentTextStyle: body(14, weight: FontWeight.w600),
        actionTextColor: colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(color: colors.border),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
        linearTrackColor: colors.surfaceRaised,
        circularTrackColor: Colors.transparent,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: colors.surfaceRaised,
          selectedBackgroundColor: colors.accent.withValues(alpha: 0.22),
          selectedForegroundColor: colors.textColor,
          foregroundColor: colors.mutedTextColor,
          textStyle: body(14, weight: FontWeight.w600),
          side: BorderSide(color: colors.border),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        headerHeadlineStyle: display(24, FontWeight.w700),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(colors.mutedTextColor.withValues(alpha: 0.35)),
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(4),
      ),
    );
  }
}
