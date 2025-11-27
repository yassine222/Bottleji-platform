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
    ),
    textTheme: AppTypography.getTextTheme(true),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF00695C),
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
} 