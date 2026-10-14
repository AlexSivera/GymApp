import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme_mode.dart';
import 'z_palette.dart';

// GymZ: a single dark "noche de entrenamiento" look. Everything that reads
// AppColors (cards, buttons, status colors…) follows this one palette; the
// ki/aura hues that have no generic role live in ZColors (z_palette.dart).
// The old five palettes and the theme picker were dropped with the switch to
// GymZ, so themeFor ignores the stored mode.
class AppTheme {
  AppTheme._();

  static const _gymz = AppColors(
    accent: ZColors.gi,
    accentForeground: Color(0xFFFFFFFF),
    background: ZColors.night,
    surface: Color(0xFF141A3E),
    surfaceRaised: ZColors.panelRaised,
    border: ZColors.line,
    textColor: ZColors.ink,
    mutedTextColor: ZColors.muted,
    // Completed = an esfera's orange, planned = a signal on the radar.
    statusCompleted: ZColors.ball,
    statusPlanned: ZColors.scouter,
    statusSkipped: ZColors.kaioken,
    statusRest: Color(0xFF7B86D6),
    statusEmpty: Color(0xFF2A3160),
  );

  static ThemeData get gymz => _buildTheme(_gymz, Brightness.dark);

  static AppColors colorsFor(AppThemeMode mode) => _gymz;

  static ThemeData themeFor(AppThemeMode mode) => gymz;

  // Families declared in pubspec.yaml (bundled TTFs, no runtime download).
  // Big display/headline slots use the heavy GymZ face; titles stay on
  // Outfit, which reads better at list-row sizes.
  static const headingFont = ZFonts.display;
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

    // Heading face: Dela Gothic One — the heavy GymZ display face, for the
    // big display/headline slots and app bar titles. It runs wide, so those
    // slots are a notch smaller than they were with Outfit. Title face:
    // Outfit — a geometric sans for list rows and card titles. Body face: Plus Jakarta Sans — warm
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
    TextStyle heading(double size, {double? height}) => TextStyle(
          fontFamily: headingFont,
          fontSize: size,
          fontWeight: FontWeight.w400,
          height: height ?? 1.12,
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
      displayLarge: heading(44, height: 1.0),
      displayMedium: heading(36, height: 1.0),
      // Hero numbers / big CTAs.
      displaySmall: heading(30, height: 1.05),
      headlineLarge: heading(25),
      headlineMedium: heading(21),
      headlineSmall: heading(19),
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
        titleTextStyle: heading(19),
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
