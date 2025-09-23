import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/core/theme/theme_controller.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeControllerProvider) == ThemeMode.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bottleji Theme Demo'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typography Demo', style: theme.textTheme.displayLarge),
            const SizedBox(height: 16),
            
            Text('Display Large', style: theme.textTheme.displayLarge),
            Text('Display Medium', style: theme.textTheme.displayMedium),
            Text('Display Small', style: theme.textTheme.displaySmall),
            Text('Body Large', style: theme.textTheme.bodyLarge),
            Text('Body Medium', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),

            Text('Buttons Demo', style: theme.textTheme.displaySmall),
            const SizedBox(height: 16),
            
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Elevated Button'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined Button'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Cards Demo', style: theme.textTheme.displaySmall),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card Title', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('This is a card with theme-based styling.',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Status Indicators', style: theme.textTheme.displaySmall),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 8,
              children: [
                _StatusChip(
                  label: 'Collected',
                  color: AppColors.statusCollected,
                ),
                _StatusChip(
                  label: 'Pending',
                  color: AppColors.statusPending,
                ),
                _StatusChip(
                  label: 'Refused',
                  color: AppColors.statusRefused,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('Map Pin Demo', style: theme.textTheme.displaySmall),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isDarkMode ? AppColors.darkMapPin : AppColors.lightMapPin,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text('Collection Point',
                    style: theme.textTheme.bodyLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      side: BorderSide(color: color),
    );
  }
} 