# Localization Implementation Plan for Bottleji App

## 📋 Overview
This document outlines a comprehensive plan for implementing full localization (i18n) support in the Bottleji Flutter app. The app currently has a "Language" section in settings marked as "Coming Soon" - this plan will make it fully functional.

## 🎯 Goals
1. Support multiple languages (starting with English, French, German, Arabic)
2. Allow users to change language from Settings
3. Persist language preference across app restarts
4. Integrate seamlessly with existing Riverpod state management
5. Follow Flutter best practices for localization

## 🏗️ Architecture & Approach

### Recommended Approach: `flutter_localizations` + `intl` + Custom Provider
- **Package**: `flutter_localizations` (Flutter SDK) + `intl` (already in pubspec.yaml)
- **Method**: ARB (Application Resource Bundle) files for translations
- **State Management**: Riverpod provider (similar to ThemeController pattern)
- **Storage**: SharedPreferences (already used in app)

### Why This Approach?
- ✅ Official Flutter solution, well-maintained
- ✅ Supports pluralization, gender, date/time formatting
- ✅ Works with Material/Cupertino widgets
- ✅ Easy to add new languages
- ✅ Type-safe with code generation
- ✅ Follows the same pattern as ThemeController

## 📦 Dependencies

### Add to `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0  # Already present
```

### Add to `pubspec.yaml` (flutter section):
```yaml
flutter:
  generate: true  # Enable code generation for l10n
```

## 📁 File Structure

```
botleji/
├── lib/
│   ├── core/
│   │   ├── localization/
│   │   │   ├── app_localizations.dart          # Generated (don't edit)
│   │   │   ├── app_localizations_delegate.dart # Generated (don't edit)
│   │   │   └── localization_controller.dart     # Riverpod controller
│   │   └── ...
│   └── ...
├── l10n/
│   ├── app_en.arb                              # English translations
│   ├── app_fr.arb                              # French translations
│   ├── app_de.arb                              # German translations
│   ├── app_ar.arb                              # Arabic translations
│   └── l10n.yaml                               # Configuration
└── pubspec.yaml
```

## 🌍 Supported Languages (Initial)

1. **English (en)** - Default/Base language
2. **French (fr)** - For French-speaking users
3. **German (de)** - For German-speaking users
4. **Arabic (ar)** - RTL support needed

*Note: Can easily add more languages later by adding new ARB files*

## 📝 Implementation Steps

### Phase 1: Setup & Configuration
1. ✅ Add dependencies to `pubspec.yaml`
2. ✅ Create `l10n/` directory structure
3. ✅ Create `l10n.yaml` configuration file
4. ✅ Create initial ARB files for all languages
5. ✅ Run code generation to create localization classes

### Phase 2: Core Infrastructure
1. ✅ Create `LocalizationController` (Riverpod StateNotifier)
2. ✅ Create localization provider
3. ✅ Integrate with `MaterialApp` in `main.dart`
4. ✅ Add language persistence (SharedPreferences)
5. ✅ Create language selection screen

### Phase 3: Translation Files
1. ✅ Extract all hardcoded strings from the app
2. ✅ Create translation keys in ARB files
3. ✅ Translate to all supported languages
4. ✅ Handle pluralization where needed
5. ✅ Handle date/time formatting

### Phase 4: UI Integration
1. ✅ Replace hardcoded strings with `AppLocalizations.of(context)`
2. ✅ Update Settings screen to remove "Coming Soon"
3. ✅ Create language selection screen
4. ✅ Add language change confirmation dialog
5. ✅ Handle RTL layout for Arabic

### Phase 5: Testing & Refinement
1. ✅ Test language switching
2. ✅ Test persistence across app restarts
3. ✅ Test RTL layout for Arabic
4. ✅ Verify all screens are translated
5. ✅ Test date/time/number formatting

## 🔧 Technical Details

### 1. Localization Controller (Similar to ThemeController)

```dart
// lib/core/localization/localization_controller.dart
class LocalizationController extends StateNotifier<Locale> {
  static const String _localeKey = 'selected_locale';
  
  LocalizationController() : super(const Locale('en')) {
    _loadSavedLocale();
  }
  
  Future<void> setLocale(Locale locale) async {
    // Save to SharedPreferences
    // Update state
  }
  
  Future<void> _loadSavedLocale() async {
    // Load from SharedPreferences
  }
}
```

### 2. MaterialApp Integration

```dart
// In main.dart
MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en', ''),
    Locale('fr', ''),
    Locale('de', ''),
    Locale('ar', ''),
  ],
  locale: ref.watch(localizationControllerProvider),
  // ... rest of config
)
```

### 3. ARB File Structure

```json
// l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "Bottleji",
  "@appTitle": {
    "description": "The application title"
  },
  "settings": "Settings",
  "language": "Language",
  "changeLanguage": "Change app language",
  "selectLanguage": "Select Language",
  "english": "English",
  "french": "French",
  "german": "German",
  "arabic": "Arabic",
  "login": "Login",
  "email": "Email",
  "password": "Password",
  // ... more keys
}
```

### 4. Usage in Widgets

```dart
// Before
Text('Settings')

// After
Text(AppLocalizations.of(context)!.settings)
```

## 📱 Settings Screen Integration

### Update Settings Screen
- Remove "Coming Soon" badge
- Make Language card functional
- Navigate to Language Selection Screen

### New Language Selection Screen
- List of available languages with flags/icons
- Current language indicator
- Language change confirmation
- Immediate language switch on selection

## 🔄 Migration Strategy

### Step-by-Step Migration
1. **Start with core screens**: Login, Settings, Home
2. **Move to feature screens**: Profile, History, Rewards, etc.
3. **Handle edge cases**: Error messages, dialogs, snackbars
4. **Update dynamic content**: Format dates, numbers, currencies

### String Extraction Priority
1. **High Priority** (User-facing, frequently seen):
   - Login/Register screens
   - Settings screens
   - Home screen
   - Navigation labels
   - Error messages

2. **Medium Priority**:
   - Profile screens
   - History screens
   - Rewards screens
   - Support screens

3. **Low Priority** (Less frequently seen):
   - Debug screens
   - Admin features
   - Developer tools

## 🎨 RTL Support (Arabic)

### Considerations
- Use `Directionality` widget where needed
- Test all layouts in RTL mode
- Ensure icons and images flip correctly
- Test navigation drawer in RTL
- Verify text alignment

### Implementation
```dart
// MaterialApp automatically handles RTL for Arabic
// But may need manual adjustments for custom layouts
Directionality(
  textDirection: Localizations.localeOf(context).languageCode == 'ar'
      ? TextDirection.rtl
      : TextDirection.ltr,
  child: YourWidget(),
)
```

## 📊 Translation Keys Organization

### Categories of Keys
1. **Common**: buttons, labels, actions (OK, Cancel, Save, Delete)
2. **Navigation**: drawer items, tab labels, menu items
3. **Auth**: login, register, password reset
4. **Settings**: all settings-related strings
5. **Features**: drops, collections, rewards, history
6. **Errors**: error messages, validation messages
7. **Success**: success messages, confirmations
8. **Time/Date**: relative time, date formats

### Naming Convention
- Use camelCase: `loginButton`, `settingsTitle`
- Group by feature: `auth_login`, `settings_language`
- Be descriptive: `collectionSuccessMessage` not `msg1`

## 🧪 Testing Checklist

- [ ] Language switching works immediately
- [ ] Language preference persists after app restart
- [ ] All screens display correct language
- [ ] RTL layout works for Arabic
- [ ] Date/time formatting is locale-aware
- [ ] Number formatting is locale-aware
- [ ] Pluralization works correctly
- [ ] No hardcoded strings remain
- [ ] Error messages are translated
- [ ] Loading states are translated

## 🚀 Future Enhancements

1. **Dynamic Language Loading**: Load translations from server
2. **Language Packs**: Allow users to download additional languages
3. **Translation Management**: Integration with translation services
4. **Context-Aware Translations**: Different translations based on user role
5. **Voice/Text-to-Speech**: Localized voice prompts

## 📚 Resources

- [Flutter Internationalization Guide](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [intl Package Documentation](https://pub.dev/packages/intl)
- [ARB File Format](https://github.com/google/app-resource-bundle)

## ⚠️ Important Notes

1. **Code Generation**: Run `flutter gen-l10n` or `flutter pub get` after adding ARB files
2. **Build Runner**: Not needed for l10n (uses Flutter's built-in generator)
3. **Hot Reload**: Language changes require hot restart (not hot reload)
4. **Testing**: Test on physical devices for RTL support
5. **Performance**: Minimal impact - translations are loaded at app start

## 📝 Estimated Effort

- **Setup & Infrastructure**: 2-3 hours
- **Translation File Creation**: 4-6 hours (depending on number of strings)
- **UI Integration**: 6-8 hours (replacing all hardcoded strings)
- **Testing & Refinement**: 2-3 hours
- **Total**: ~14-20 hours

## ✅ Success Criteria

- [ ] Users can change language from Settings
- [ ] Language preference persists
- [ ] All major screens are translated
- [ ] RTL support works for Arabic
- [ ] No hardcoded English strings in UI
- [ ] App works correctly in all supported languages

---

**Next Steps**: Review this plan, then proceed with Phase 1 implementation.

