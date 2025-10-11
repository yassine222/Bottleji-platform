import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_screen.dart';
import 'location_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Settings'),
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
            title: 'Location',
            subtitle: 'Manage location preferences',
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
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              _showComingSoonDialog(context, 'Notification Settings');
            },
          ),
          const SizedBox(height: 12),

          // Display Theme
          _buildSettingsCard(
            context: context,
            isDarkMode: isDarkMode,
            icon: Icons.palette_rounded,
            title: 'Display Theme',
            subtitle: 'Change app appearance',
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
            title: 'Language',
            subtitle: 'Change app language',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            onTap: () {
              _showComingSoonDialog(context, 'Language Settings');
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

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Coming Soon'),
          ],
        ),
        content: Text(
          '$feature will be available in a future update. Stay tuned!',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF00695C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

