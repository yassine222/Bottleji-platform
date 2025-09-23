import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/core/controllers/theme_controller.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Display theme',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _ThemeOption(
              title: 'System Default',
              subtitle: 'Use your device\'s default mode',
              icon: Icons.phone_android,
              isSelected: themeMode == ThemeMode.system,
              onTap: () {
                if (themeMode != ThemeMode.system) {
                  ref.read(themeControllerProvider.notifier).setTheme(ThemeMode.system);
                }
              },
            ),
            const Divider(),
            _ThemeOption(
              title: 'Light',
              subtitle: 'Always use light mode',
              icon: Icons.wb_sunny_outlined,
              isSelected: themeMode == ThemeMode.light,
              onTap: () {
                if (themeMode != ThemeMode.light) {
                  ref.read(themeControllerProvider.notifier).setTheme(ThemeMode.light);
                }
              },
            ),
            const Divider(),
            _ThemeOption(
              title: 'Dark',
              subtitle: 'Always use dark mode',
              icon: Icons.nightlight_round,
              isSelected: themeMode == ThemeMode.dark,
              onTap: () {
                if (themeMode != ThemeMode.dark) {
                  ref.read(themeControllerProvider.notifier).setTheme(ThemeMode.dark);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
    );
  }
}
