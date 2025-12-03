import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/core/localization/localization_controller.dart';
import 'package:botleji/l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          l10n.selectLanguage,
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
              ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.15),
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
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
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

