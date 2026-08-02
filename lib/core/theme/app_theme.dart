import 'package:flutter/material.dart';

// Dark, minimal theme in the spirit of Whoop/Oura: near-black surfaces,
// a single accent color, generous spacing handled at the widget level.
class AppTheme {
  AppTheme._();

  static const accent = Color(0xFF5EEAD4);
  static const background = Color(0xFF0B0D0F);
  static const surface = Color(0xFF16191C);

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.18),
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
