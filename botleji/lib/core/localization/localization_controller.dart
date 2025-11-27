import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LocalizationController extends StateNotifier<Locale> {
  static const String _localeKey = 'selected_locale';
  static const String _hasDetectedSystemLocaleKey = 'has_detected_system_locale';
  static const Locale _defaultLocale = Locale('en');
  
  LocalizationController() : super(_defaultLocale) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);
      final hasDetectedSystemLocale = prefs.getBool(_hasDetectedSystemLocaleKey) ?? false;
      
      if (savedLocaleCode != null) {
        // User has previously selected a language
        final locale = _stringToLocale(savedLocaleCode);
        state = locale;
      } else if (!hasDetectedSystemLocale) {
        // First launch - detect system language
        final systemLocale = _detectSystemLocale();
        state = systemLocale;
        // Save the detected locale and mark that we've detected it
        await prefs.setString(_localeKey, _localeToString(systemLocale));
        await prefs.setBool(_hasDetectedSystemLocaleKey, true);
      } else {
        // Fallback to default
        state = _defaultLocale;
      }
    } catch (e) {
      // If there's an error loading, keep the default locale
      state = _defaultLocale;
    }
  }

  Locale _detectSystemLocale() {
    try {
      // Get system locale from platform
      final systemLocales = ui.PlatformDispatcher.instance.locales;
      
      if (systemLocales.isNotEmpty) {
        final systemLocale = systemLocales.first;
        final languageCode = systemLocale.languageCode.toLowerCase();
        
        // Check if system language is supported
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == languageCode) {
            return supportedLocale;
          }
        }
      }
      
      // Fallback to default if system language not supported
      return _defaultLocale;
    } catch (e) {
      // Fallback to default on error
      return _defaultLocale;
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, _localeToString(locale));
      // Mark that user has manually selected a language
      await prefs.setBool(_hasDetectedSystemLocaleKey, true);
      state = locale;
    } catch (e) {
      // If there's an error saving, still update the state
      state = locale;
    }
  }

  String _localeToString(Locale locale) {
    return '${locale.languageCode}_${locale.countryCode ?? ''}';
  }

  Locale _stringToLocale(String localeString) {
    final parts = localeString.split('_');
    if (parts.length == 2 && parts[1].isNotEmpty) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  // Helper method to get supported locales
  static List<Locale> get supportedLocales => const [
    Locale('en', ''),
    Locale('fr', ''),
    Locale('de', ''),
    Locale('ar', ''),
  ];

  // Helper method to get locale display name
  static String getLocaleDisplayName(Locale locale, BuildContext context) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      case 'ar':
        return 'العربية';
      default:
        return locale.languageCode;
    }
  }
}

final localizationControllerProvider =
    StateNotifierProvider<LocalizationController, Locale>((ref) {
  return LocalizationController();
});

