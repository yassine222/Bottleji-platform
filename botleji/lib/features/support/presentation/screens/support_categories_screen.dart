import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/support/presentation/screens/support_item_selection_screen.dart';
import 'package:botleji/l10n/app_localizations.dart';

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
        title: Text(
          AppLocalizations.of(context).supportCategories,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(AppLocalizations.of(context).userNotFound));
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
                              AppLocalizations.of(context).whatDoYouNeedHelpWith,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: appGreenColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context).selectCategoryToContinue,
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
                  AppLocalizations.of(context).supportCategories,
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
                    title: AppLocalizations.of(context).dropIssues,
                    description: AppLocalizations.of(context).getHelpWithDropProblems,
                    subtitle: AppLocalizations.of(context).dropIssuesSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SupportItemSelectionScreen(
                            category: 'drops',
                            categoryTitle: AppLocalizations.of(context).dropIssues,
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
                    title: AppLocalizations.of(context).applicationIssues,
                    description: AppLocalizations.of(context).getHelpWithApplications,
                    subtitle: AppLocalizations.of(context).applicationIssuesSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SupportItemSelectionScreen(
                            category: 'applications',
                            categoryTitle: AppLocalizations.of(context).applicationIssues,
                          ),
                        ),
                      );
                    },
                  ),

                // Account Issues Category
                _buildCategoryCard(
                  context: context,
                  icon: Icons.account_circle,
                  title: AppLocalizations.of(context).accountIssues,
                  description: AppLocalizations.of(context).getHelpWithAccount,
                  subtitle: AppLocalizations.of(context).accountIssuesSubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SupportItemSelectionScreen(
                          category: 'account',
                          categoryTitle: AppLocalizations.of(context).accountIssues,
                        ),
                      ),
                    );
                  },
                ),

                // Technical Issues Category
                _buildCategoryCard(
                  context: context,
                  icon: Icons.bug_report,
                  title: AppLocalizations.of(context).technicalIssues,
                  description: AppLocalizations.of(context).getHelpWithAppProblems,
                  subtitle: AppLocalizations.of(context).technicalIssuesSubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SupportItemSelectionScreen(
                          category: 'technical',
                          categoryTitle: AppLocalizations.of(context).technicalIssues,
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
                    title: AppLocalizations.of(context).paymentIssues,
                    description: AppLocalizations.of(context).getHelpWithPayments,
                    subtitle: AppLocalizations.of(context).paymentIssuesSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SupportItemSelectionScreen(
                            category: 'payments',
                            categoryTitle: AppLocalizations.of(context).paymentIssues,
                          ),
                        ),
                      );
                    },
                  ),

                // General Support Category
                _buildCategoryCard(
                  context: context,
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context).generalSupport,
                  description: AppLocalizations.of(context).getHelpWithAnythingElse,
                  subtitle: AppLocalizations.of(context).generalSupportSubtitle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SupportItemSelectionScreen(
                          category: 'general',
                          categoryTitle: AppLocalizations.of(context).generalSupport,
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
          child: Text(AppLocalizations.of(context).errorColon(error.toString())),
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
