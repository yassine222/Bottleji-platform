import 'package:flutter/material.dart';
import 'package:botleji/core/theme/app_typography.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00695C),
    ),
    textTheme: AppTypography.getTextTheme(false),
    scaffoldBackgroundColor: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00695C),
    ).background,
    cardTheme: CardThemeData(
      color: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00695C),
      ).surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00695C),
      ).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF00695C),
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00695C),
      brightness: Brightness.dark,
    ).copyWith(
      // Explicitly set all primary-related colors to use 0xFF00695C
      // This ensures consistency across all auto-generated primary colors
      primary: const Color(0xFF00695C),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF00695C).withOpacity(0.15), // Subtle container background
      onPrimaryContainer: Colors.white, // Text on primary containers should be white
      // Ensure proper contrast between background and surface (cards)
      // Background is the darkest, surface should be lighter for cards
      // Using colors that match the app's dark theme design
      background: const Color(0xFF001B29), // Dark background matching app design
      surface: const Color(0xFF002B3B), // Lighter surface for cards (distinguishable from background)
      surfaceVariant: const Color(0xFF003A4D), // Even lighter for elevated surfaces
      onSurface: const Color(0xFFEDEDED), // Text on surface
      onSurfaceVariant: const Color(0xFFBDBDBD), // Secondary text on surface
    ),
    textTheme: AppTypography.getTextTheme(true),
    scaffoldBackgroundColor: const Color(0xFF001B29), // Explicit dark background
    cardTheme: CardThemeData(
      color: const Color(0xFF002B3B), // Explicit surface color for cards (lighter than background)
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF002B3B), // Explicit surface color for dialogs
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF00695C),
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
} 