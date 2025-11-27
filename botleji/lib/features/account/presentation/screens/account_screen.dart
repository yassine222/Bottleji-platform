import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/core/theme/app_colors.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:botleji/features/collector/presentation/screens/collector_application_screen.dart';
import 'package:botleji/features/collector/presentation/screens/collector_application_status_screen.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';
import 'package:botleji/l10n/app_localizations.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);
    const appGreenColor = Color(0xFF00695C);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context).myAccount,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 80,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return Text(
                        l10n.pleaseLoginToViewProfile,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return FilledButton.icon(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        icon: const Icon(Icons.login),
                        label: Text(l10n.login),
                    style: FilledButton.styleFrom(
                      backgroundColor: appGreenColor,
                      foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      ),
                    );
                    },
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        appGreenColor,
                        appGreenColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: appGreenColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Photo
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: user.profilePhoto != null
                              ? NetworkImage(user.profilePhoto!)
                              : null,
                          child: user.profilePhoto == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: appGreenColor,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // User Name
                      Builder(
                        builder: (context) {
                          final l10n = AppLocalizations.of(context);
                          return Text(
                            user.name ?? l10n.notSet,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      // Email
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Profile Information Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return Text(
                              l10n.profileInformation,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        
                        // Full Name
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildInfoTile(
                              context,
                              icon: Icons.person_outline,
                              title: l10n.fullName,
                              value: user.name ?? l10n.notSet,
                              iconColor: appGreenColor,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Email
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildInfoTile(
                              context,
                              icon: Icons.email_outlined,
                              title: l10n.email,
                              value: user.email,
                              iconColor: AppColors.lightSecondary,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Phone
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildInfoTile(
                              context,
                              icon: Icons.phone_outlined,
                              title: l10n.phone,
                              value: user.phoneNumber ?? l10n.notSet,
                              iconColor: AppColors.lightMapPin,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Address
                        Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            return _buildInfoTile(
                              context,
                              icon: Icons.location_on_outlined,
                              title: l10n.address,
                              value: user.address ?? l10n.notSet,
                              iconColor: AppColors.lightSuccess,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Collector Application Status
                Consumer(
                  builder: (context, ref, child) {
                    return userAsync.when(
                      data: (user) {
                        if (user == null) {
                          return const SizedBox.shrink();
                        }

                        if (user.isCollector) {
                          // User is already a collector
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: appGreenColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: appGreenColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified, color: appGreenColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final l10n = AppLocalizations.of(context);
                                          return Text(
                                            l10n.collectorStatus,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: appGreenColor,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (context) {
                                          final l10n = AppLocalizations.of(context);
                                          return Text(
                                            l10n.approvedCollector,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Check application status from user data
                        final applicationStatus = user.collectorApplicationStatus;
                        
                        if (applicationStatus != null) {
                          switch (applicationStatus) {
                            case CollectorApplicationStatus.pending:
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.schedule, color: Colors.orange, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final l10n = AppLocalizations.of(context);
                                              return Text(
                                                l10n.applicationStatus,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.orange,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          Builder(
                                            builder: (context) {
                                              final l10n = AppLocalizations.of(context);
                                              return Text(
                                                l10n.applicationUnderReviewStatus,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final l10n = AppLocalizations.of(context);
                                        return TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const CollectorApplicationStatusScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(l10n.viewDetails),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            case CollectorApplicationStatus.rejected:
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.cancel, color: Colors.red, size: 24),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Builder(
                                                builder: (context) {
                                                  final l10n = AppLocalizations.of(context);
                                                  return Text(
                                                    l10n.applicationRejectedTitle,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.red.shade800,
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(height: 4),
                                              Builder(
                                                builder: (context) {
                                                  final l10n = AppLocalizations.of(context);
                                                  return Text(
                                                    l10n.tapToViewRejectionReason,
                                                    style: TextStyle(
                                                      color: Colors.red.shade600,
                                                      fontSize: 14,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showRejectionReason(context, user),
                                          child: Icon(
                                            Icons.info_outline,
                                            color: Colors.red.shade600,
                                            size: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const CollectorApplicationScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: Builder(
                                          builder: (context) => Text(AppLocalizations.of(context).editApplication),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade700,
                                          side: BorderSide(color: Colors.red.shade300),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            case CollectorApplicationStatus.approved:
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: appGreenColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: appGreenColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.verified, color: appGreenColor, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final l10n = AppLocalizations.of(context);
                                              return Text(
                                                l10n.collectorStatus,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: appGreenColor,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 4),
                                          Builder(
                                            builder: (context) {
                                              final l10n = AppLocalizations.of(context);
                                              return Text(
                                                l10n.approvedCollector,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                          }
                        }

                        // No application - show apply button
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CollectorApplicationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.eco),
                            label: Text(AppLocalizations.of(context).becomeACollector),
                            style: FilledButton.styleFrom(
                              backgroundColor: appGreenColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                    },
                    loading: () => Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: appGreenColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading application status...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (error, stack) => SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CollectorApplicationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.eco),
                          label: Text(AppLocalizations.of(context).becomeACollector),
                          style: FilledButton.styleFrom(
                            backgroundColor: appGreenColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Edit Profile Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileSetupScreen(email: user.email),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: Builder(
                      builder: (context) => Text(AppLocalizations.of(context).editProfile),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: appGreenColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: appGreenColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading profile',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (error.toString().toLowerCase().contains('unauthorized') ||
                  error.toString().contains('401')) ...[
                FilledButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout(ref);
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: appGreenColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(authNotifierProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: appGreenColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static void _showRejectionReason(BuildContext context, UserData user) {
    final l10n = AppLocalizations.of(context);
    final rejectionReason = user.collectorApplicationRejectionReason ?? l10n.noSpecificReason;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.applicationRejectedTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.applicationRejectedMessage(rejectionReason),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                rejectionReason,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.canEditApplication,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectorApplicationScreen(),
                ),
              );
            },
            child: Text(l10n.editApplication),
          ),
        ],
      ),
    );
  }
} 