import 'package:riverpod/riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Manual provider definitions (no code generation needed)
class ThemeController extends StateNotifier<ThemeMode> {
  static const String themeKey = 'selected_theme';

  ThemeController() : super(ThemeMode.light) {
    _loadSavedTheme();
  }

  void _loadSavedTheme() {
    SharedPreferences.getInstance().then((prefs) {
      final savedTheme = prefs.getString(themeKey);
      if (savedTheme != null) {
        final themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.light,
        );
        if (state != themeMode) {
          state = themeMode;
        }
      }
    });
  }

  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeKey, newTheme.toString());
    state = newTheme;
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
}); 