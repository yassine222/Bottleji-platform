import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/l10n/app_localizations.dart';
import 'package:botleji/core/localization/localization_controller.dart';
import 'theme_screen.dart';
import 'location_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'language_selection_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(localizationControllerProvider);
    final currentLanguageName = LocalizationController.getLocaleDisplayName(currentLocale, context);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location Settings
          _buildSettingsCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.location_on_rounded,
            title: l10n.location,
            subtitle: l10n.manageLocationPreferences,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Notification Settings
          _buildSettingsCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.notifications_rounded,
            title: l10n.notifications,
            subtitle: l10n.manageNotificationPreferences,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Display Theme
          _buildSettingsCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.palette_rounded,
            title: l10n.displayTheme,
            subtitle: l10n.changeAppAppearance,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeScreen()),
              );
            },
          ),
          const SizedBox(height: 12),

          // Language Settings
          _buildSettingsCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.language_rounded,
            title: l10n.language,
            subtitle: l10n.changeLanguage,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00695C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00695C).withOpacity(0.3)),
              ),
              child: Text(
                currentLanguageName,
                style: const TextStyle(
                  color: Color(0xFF00695C),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            icon,
            color: const Color(0xFF00695C),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: trailing ??
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
        onTap: onTap,
      ),
    );
  }

}

