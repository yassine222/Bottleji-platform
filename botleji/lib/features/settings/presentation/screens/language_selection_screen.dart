import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/core/localization/localization_controller.dart';
import 'package:botleji/l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final currentLocale = ref.watch(localizationControllerProvider);
    final localizationController = ref.read(localizationControllerProvider.notifier);
    final l10n = AppLocalizations.of(context);

    final languages = [
      const Locale('en', ''),
      const Locale('fr', ''),
      const Locale('de', ''),
      const Locale('ar', ''),
    ];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: languages.map((locale) {
          final isSelected = locale.languageCode == currentLocale.languageCode;
          final displayName = LocalizationController.getLocaleDisplayName(locale, context);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00695C)
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: const Color(0xFF00695C),
                  size: 24,
                ),
              ),
              title: Text(
                displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: const Color(0xFF00695C),
                      size: 24,
                    )
                  : const SizedBox.shrink(),
              onTap: () async {
                if (!isSelected) {
                  await localizationController.setLocale(locale);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${AppLocalizations.of(context).language} changed to $displayName',
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF00695C),
                      ),
                    );
                  }
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

