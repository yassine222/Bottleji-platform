import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const lightPrimary = Color(0xFF00A86B);
  static const lightSecondary = Color(0xFF0099FF);
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F5F5);
  static const lightTextPrimary = Color(0xFF1C1C1C);
  static const lightTextSecondary = Color(0xFF616161);
  static const lightError = Color(0xFFD32F2F);
  static const lightSuccess = Color(0xFF388E3C);
  static const lightMapPin = Color(0xFFFF9800);

  // Dark Theme Colors
  static const darkPrimary = Color(0xFF00A86B);     // Same as lightPrimary
  static const darkSecondary = Color(0xFF0099FF);   // Updated to match splash screen blue
  static const darkBackground = Color(0xFF001B29);   // Updated to match splash screen
  static const darkSurface = Color(0xFF002B3B);     // Slightly lighter than background for contrast
  static const darkTextPrimary = Color(0xFFEDEDED);
  static const darkTextSecondary = Color(0xFFBDBDBD);
  static const darkError = Color(0xFFD32F2F);       // Same as lightError
  static const darkSuccess = Color(0xFF388E3C);     // Same as lightSuccess
  static const darkMapPin = Color(0xFFFF9800);      // Same as lightMapPin

  // Status Colors
  static const statusCollected = Color(0xFF4CAF50);
  static const statusPending = Color(0xFFFF9800);
  static const statusRefused = Color(0xFFE53935);
} 