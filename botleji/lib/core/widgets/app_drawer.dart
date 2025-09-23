import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/collector/presentation/screens/collector_application_screen.dart';
import 'package:botleji/features/collector/presentation/screens/collector_application_status_screen.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/auth/services/mode_switch_service.dart';
import 'package:botleji/features/settings/presentation/screens/theme_screen.dart';
import 'package:botleji/features/account/presentation/screens/account_screen.dart';
import 'package:botleji/features/history/presentation/screens/history_screen.dart';
import 'package:botleji/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:botleji/features/training/presentation/screens/trainings_screen.dart';
import 'package:botleji/features/rewards/presentation/screens/refer_earn_screen.dart';
import 'package:botleji/features/support/presentation/screens/support_screen.dart';
import 'package:botleji/features/support/presentation/screens/terms_screen.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  void initState() {
    super.initState();
  }

  void _showRejectionReason(BuildContext context, UserData user) {
    final rejectionReason = user.collectorApplicationRejectionReason ?? 'No specific reason provided';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Application Rejected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your application was rejected for the following reason:',
              style: TextStyle(fontWeight: FontWeight.w600),
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
            const Text(
              'You can edit your application and submit it again.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectorApplicationScreen(),
                ),
              );
            },
            child: const Text('Edit Application'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    print('Logout button pressed');
    
    // Show confirmation dialog first
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('Logout cancelled');
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              print('Logout confirmed');
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    print('Dialog result: $shouldLogout');
    print('Context mounted: ${context.mounted}');

    if (shouldLogout == true) {
      try {
        print('Starting logout process...');
        
        // Close the drawer
        if (context.mounted) {
          Navigator.pop(context);
          print('Drawer closed');
        }
        
        // Perform logout
        await ref.read(authNotifierProvider.notifier).logout(ref);
        print('Logout completed successfully');
        
        // Navigate to login screen
        if (context.mounted) {
          print('Navigating to login screen...');
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
          print('Navigation completed');
        }
      } catch (e, stack) {
        print('Error during logout: $e');
        print('Stack trace: $stack');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error during logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleRoleChange(BuildContext context, UserMode newMode) async {
    try {
      // Get current mode
      final currentMode = ref.read(userModeControllerProvider).value;
      
      // Check if user is already in the selected mode
      if (currentMode != null && currentMode == newMode) {
        print('🔄 AppDrawer: User is already in ${newMode.name} mode, skipping switch');
        // Just close the drawer
        Navigator.pop(context);
        return;
      }
      
      print('🔄 AppDrawer: Switching from ${currentMode?.name ?? 'unknown'} to ${newMode.name}');
      
      // Check if user is trying to switch to collector mode
      if (newMode == UserMode.collector) {
        final authState = ref.read(authNotifierProvider);
        final user = authState.value;
        
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to access collector mode'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        // Check application status first, then roles
        final applicationStatus = user.collectorApplicationStatus;
        print('🔍 AppDrawer: User application status from shared preferences: $applicationStatus');
        
        // Priority 1: If user has collector role and isCollector is true, allow mode switch (legacy collectors)
        if (user.isCollector && user.roles.contains('collector')) {
          print('🔄 AppDrawer: Legacy collector - has collector role and isCollector is true, allowing mode switch to collector');
        }
        // Priority 2: If user has collector role and application is approved, allow mode switch
        else if (user.roles.contains('collector') && applicationStatus == CollectorApplicationStatus.approved) {
          print('🔄 AppDrawer: User has collector role and approved application, allowing mode switch to collector');
        } else {
          // User needs to apply or has pending/rejected application
          String dialogMessage;
          String buttonText;
          bool shouldNavigateToStatus = false;
          bool shouldNavigateToEdit = false;
          
          if (applicationStatus != null) {
            switch (applicationStatus) {
              case CollectorApplicationStatus.pending:
                dialogMessage = 'Your application is currently under review. Would you like to view your application status?';
                buttonText = 'View Status';
                shouldNavigateToStatus = true;
                shouldNavigateToEdit = false;
                break;
              case CollectorApplicationStatus.rejected:
                final rejectionReason = user.collectorApplicationRejectionReason ?? 'No specific reason provided';
                dialogMessage = 'Your application was rejected for the following reason:\n\n"$rejectionReason"\n\nWould you like to edit your application and submit it again?';
                buttonText = 'Edit Application';
                shouldNavigateToStatus = false;
                shouldNavigateToEdit = true;
                break;
              case CollectorApplicationStatus.approved:
                // Application approved but no collector role (might be reversed)
                dialogMessage = 'Your application was approved but your collector access has been temporarily suspended. Please contact support or reapply.';
                buttonText = 'Reapply';
                shouldNavigateToStatus = false;
                shouldNavigateToEdit = false;
                break;
            }
          } else {
            dialogMessage = 'You need to apply and be approved to access collector mode. Would you like to apply now?';
            buttonText = 'Apply Now';
            shouldNavigateToStatus = false;
            shouldNavigateToEdit = false;
          }
      
          // Show dialog to apply for collector status
          final shouldApply = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Become a Collector'),
              content: Text(dialogMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(buttonText),
                ),
              ],
            ),
          );
          
          if (shouldApply == true) {
            Navigator.pop(context); // Close drawer
            if (shouldNavigateToEdit) {
              // Navigate to application screen to edit existing application
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectorApplicationScreen(),
                ),
              );
            } else if (shouldNavigateToStatus) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectorApplicationStatusScreen(),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollectorApplicationScreen(),
                ),
              );
            }
          }
          return;
        }
        
        // User has collector role - allow mode switch
        print('🔄 AppDrawer: User has collector role, allowing mode switch to collector');
      }
      
      // Close the drawer first
      Navigator.pop(context);
      
      // Use the new mode switch service with splash screen
      await ModeSwitchService.switchMode(context, ref, newMode);
      
      print('🔄 AppDrawer: User mode switched to: ${newMode.name} with splash screen');

    } catch (e) {
      // Silently handle mode switching errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final userAsync = ref.watch(authNotifierProvider);
    final currentUserMode = ref.watch(userModeControllerProvider);

    return Drawer(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00695C),
                  const Color(0xFF004D40),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.recycling_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Bottleji',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // User Info
                    userAsync.when(
                      data: (user) => user != null
                          ? Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: Text(
                                    (user.name?.isNotEmpty == true) ? user.name![0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name ?? 'User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Mode Selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleRoleChange(context, UserMode.household),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: currentUserMode.when(
                          data: (mode) => mode == UserMode.household ? const Color(0xFF00695C) : Colors.transparent,
                          loading: () => const Color(0xFF00695C),
                          error: (_, __) => const Color(0xFF00695C),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.home_rounded,
                            color: currentUserMode.when(
                              data: (mode) => mode == UserMode.household ? Colors.white : Colors.grey[600],
                              loading: () => Colors.white,
                              error: (_, __) => Colors.white,
                            ),
                            size: 16,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Household',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: currentUserMode.when(
                                data: (mode) => mode == UserMode.household ? Colors.white : Colors.grey[600],
                                loading: () => Colors.white,
                                error: (_, __) => Colors.white,
                              ),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleRoleChange(context, UserMode.collector),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: currentUserMode.when(
                          data: (mode) => mode == UserMode.collector ? const Color(0xFF00695C) : Colors.transparent,
                          loading: () => Colors.transparent,
                          error: (_, __) => Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_rounded,
                            color: currentUserMode.when(
                              data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                              loading: () => Colors.grey[600],
                              error: (_, __) => Colors.grey[600],
                            ),
                            size: 16,
                          ),
                          const SizedBox(height: 4),
                          userAsync.when(
                            data: (user) {
                              if (user == null) {
                                return Text(
                                  'Collector',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: currentUserMode.when(
                                      data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                      loading: () => Colors.grey[600],
                                      error: (_, __) => Colors.grey[600],
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                );
                              }

                              final applicationStatus = user.collectorApplicationStatus;
                              
                              if (user.isCollector && user.roles.contains('collector')) {
                                return Text(
                                  'Collector',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: currentUserMode.when(
                                      data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                      loading: () => Colors.grey[600],
                                      error: (_, __) => Colors.grey[600],
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                );
                              }
                              
                              if (applicationStatus != null) {
                                switch (applicationStatus) {
                                  case CollectorApplicationStatus.pending:
                                    return Text(
                                      'Review',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: currentUserMode.when(
                                          data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                          loading: () => Colors.grey[600],
                                          error: (_, __) => Colors.grey[600],
                                        ),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    );
                                  case CollectorApplicationStatus.rejected:
                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Rejected',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: currentUserMode.when(
                                              data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                              loading: () => Colors.grey[600],
                                              error: (_, __) => Colors.grey[600],
                                            ),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        GestureDetector(
                                          onTap: () => _showRejectionReason(context, user),
                                          child: Icon(
                                            Icons.info_outline,
                                            color: currentUserMode.when(
                                              data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                              loading: () => Colors.grey[600],
                                              error: (_, __) => Colors.grey[600],
                                            ),
                                            size: 10,
                                          ),
                                        ),
                                      ],
                                    );
                                  case CollectorApplicationStatus.approved:
                                    if (user.roles.contains('collector')) {
                                      return Text(
                                        'Collector',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: currentUserMode.when(
                                            data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                            loading: () => Colors.grey[600],
                                            error: (_, __) => Colors.grey[600],
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      );
                                    } else {
                                      return Text(
                                        'Review',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: currentUserMode.when(
                                            data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                            loading: () => Colors.grey[600],
                                            error: (_, __) => Colors.grey[600],
                                          ),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10,
                                        ),
                                      );
                                    }
                                }
                              }
                              
                              if (user.roles.contains('collector')) {
                                return Text(
                                  'Collector',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: currentUserMode.when(
                                      data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                      loading: () => Colors.grey[600],
                                      error: (_, __) => Colors.grey[600],
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                );
                              }
                              
                              return Text(
                                'Apply',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: currentUserMode.when(
                                    data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                    loading: () => Colors.grey[600],
                                    error: (_, __) => Colors.grey[600],
                                  ),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              );
                            },
                            loading: () => Text(
                              'Loading...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: currentUserMode.when(
                                  data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                  loading: () => Colors.grey[600],
                                  error: (_, __) => Colors.grey[600],
                                ),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                            error: (error, stack) => Text(
                              'Apply',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: currentUserMode.when(
                                  data: (mode) => mode == UserMode.collector ? Colors.white : Colors.grey[600],
                                  loading: () => Colors.grey[600],
                                  error: (_, __) => Colors.grey[600],
                                ),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          ListTile(
            leading: Icon(
              Icons.person_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('My Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.notifications_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.school_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('Trainings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrainingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.card_giftcard_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('Refer and Earn'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReferEarnScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.palette_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('Display Theme'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThemeScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.support_agent_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('Support'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.description_rounded,
              color: isDarkMode ? const Color(0xFF00695C) : const Color(0xFF00695C),
            ),
            title: const Text('Terms and Conditions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}