import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/support/presentation/screens/support_item_selection_screen.dart';

const appGreenColor = Color(0xFF00695C);

class SupportCategoriesScreen extends ConsumerWidget {
  const SupportCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Support Categories',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appGreenColor.withOpacity(0.1),
                        appGreenColor.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: appGreenColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: appGreenColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: appGreenColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What do you need help with?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: appGreenColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a category to continue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Categories
                Text(
                  'Support Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appGreenColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Drop Issues Category
                if (user.roles.contains('household') ||
                    user.roles.contains('collector'))
                  _buildCategoryCard(
                    context: context,
                    icon: Icons.local_drink,
                    title: 'Drop Issues',
                    description: 'Get help with drop-related problems',
                    subtitle:
                        'Expired drops, canceled collections, active collections',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SupportItemSelectionScreen(
                            category: 'drops',
                            categoryTitle: 'Drop Issues',
                          ),
                        ),
                      );
                    },
                  ),

                // Application Issues Category
                if (user.roles.contains('household'))
                  _buildCategoryCard(
                    context: context,
                    icon: Icons.assignment_ind,
                    title: 'Application Issues',
                    description: 'Get help with collector applications',
                    subtitle: 'Rejected applications, pending reviews',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SupportItemSelectionScreen(
                            category: 'applications',
                            categoryTitle: 'Application Issues',
                          ),
                        ),
                      );
                    },
                  ),

                // Account Issues Category
                _buildCategoryCard(
                  context: context,
                  icon: Icons.account_circle,
                  title: 'Account Issues',
                  description: 'Get help with your account',
                  subtitle:
                      'Profile updates, login problems, account settings',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SupportItemSelectionScreen(
                          category: 'account',
                          categoryTitle: 'Account Issues',
                        ),
                      ),
                    );
                  },
                ),

                // Technical Issues Category
                _buildCategoryCard(
                  context: context,
                  icon: Icons.bug_report,
                  title: 'Technical Issues',
                  description: 'Get help with app problems',
                  subtitle: 'App crashes, bugs, performance issues',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SupportItemSelectionScreen(
                          category: 'technical',
                          categoryTitle: 'Technical Issues',
                        ),
                      ),
                    );
                  },
                ),

                // Payment Issues Category
                if (user.roles.contains('collector'))
                  _buildCategoryCard(
                    context: context,
                    icon: Icons.payment,
                    title: 'Payment Issues',
                    description: 'Get help with payments',
                    subtitle:
                        'Payment delays, missing payments, payment methods',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SupportItemSelectionScreen(
                            category: 'payments',
                            categoryTitle: 'Payment Issues',
                          ),
                        ),
                      );
                    },
                  ),

                // General Support Category
                _buildCategoryCard(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'General Support',
                  description: 'Get help with anything else',
                  subtitle: 'Questions, suggestions, other issues',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const SupportItemSelectionScreen(
                          category: 'general',
                          categoryTitle: 'General Support',
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appGreenColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: appGreenColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
