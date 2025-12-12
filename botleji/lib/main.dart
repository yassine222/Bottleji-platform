import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/core/theme/app_theme.dart';
import 'package:botleji/core/localization/localization_controller.dart';
import 'package:botleji/l10n/app_localizations.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/auth/presentation/screens/login_screen.dart';
import 'package:botleji/features/home/presentation/screens/home_screen.dart';
import 'package:botleji/features/history/presentation/screens/history_screen.dart';
import 'package:botleji/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:botleji/core/controllers/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:botleji/core/utils/logger.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/services/local_notification_service.dart';
import 'package:botleji/core/services/timezone_service.dart';
import 'package:botleji/features/auth/services/mode_switch_service.dart';
import 'package:botleji/features/splash/presentation/screens/splash_screen.dart';
import 'package:botleji/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:botleji/features/onboarding/presentation/screens/permissions_screen.dart';
import 'package:botleji/features/rewards/presentation/providers/collection_success_provider.dart';
import 'package:botleji/features/rewards/presentation/widgets/collection_success_popup.dart';
import 'package:botleji/features/notifications/data/services/notification_service.dart';
import 'package:botleji/core/services/global_live_activity_manager.dart';
import 'package:botleji/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:flutter/services.dart';
// Network initialization is deferred to splash to avoid early iOS prompts
// import 'package:botleji/core/services/network_initialization_service.dart';
// import 'package:botleji/core/config/server_config.dart';
import 'package:botleji/core/config/server_config.dart';
import 'package:botleji/core/services/fcm_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();

  // Reset mode switch splash screen flag on app startup
  ModeSwitchService.resetRestartFlag();

  // Initialize timezone service for German timezone
  await TimezoneService.initialize();

  // Initialize server config caches (decides tunnel vs local IP before any sync URL is read)
  await ServerConfig.init();

  // Force use of Cloudflare Tunnel for all network calls (avoids local network probing on iOS)
  // Quick tunnel URL from `cloudflared tunnel --url http://localhost:3000`
  await ServerConfig.setTunnelUrlOverride(
    'https://bottleji-api.onrender.com',
  );

  // Defer network detection and notification service initialization
  // to run after the splash animation to avoid early iOS prompts.

  // Initialize local notification service
  await LocalNotificationService().initialize();

  // Set up notification tap handling
  LocalNotificationService().handleNotificationTap = (payload) async {
    AppLogger.log('🔔 Main: Notification tapped with payload: $payload');
    if (payload != null && payload.startsWith('force_logout:')) {
      final reason = payload.substring('force_logout:'.length);
      AppLogger.log('🔔 Main: Force logout notification tapped, reason: $reason');

      // Store the reason to show dialog when app is ready
      LocalNotificationService().showForceLogoutDialog(reason);
    }
  };

  // Set up global error handling for 401 errors
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.log('Global error: ${details.exception}');

    // Check if it's a 401 error
    if (details.exception.toString().contains('401')) {
      AppLogger.log('Global 401 error detected');
      // This will be handled by the auth provider
    }
  };

  try {
    AppLogger.log('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.log('Firebase initialized successfully');

    // Set up FCM background message handler (must be top-level function)
    // This is safe to call even if FCM is not fully configured
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      AppLogger.log('FCM background message handler registered');
    } catch (e) {
      AppLogger.log('⚠️ Could not register FCM background handler: $e');
      AppLogger.log('ℹ️ App will continue to work, but background notifications may not work');
    }

    // Defer FCM initialization until after onboarding is completed
    // FCM will be initialized in the permissions screen after user grants permission
    AppLogger.log('FCM initialization deferred until after onboarding');

    // Wait longer for Firebase Auth to be ready
    AppLogger.log('Waiting for Firebase Auth to be ready...');
    await Future.delayed(const Duration(milliseconds: 2000));
    AppLogger.log('Firebase Auth should be ready now');
  } catch (e, stackTrace) {
    AppLogger.log('Error initializing Firebase: $e');
    AppLogger.log('Stack trace: $stackTrace');
    AppLogger.log('Continuing without Firebase...');
  }

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  // Global navigator key to access navigator from anywhere
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _isAccountDisabledDialogShowing = false; // Flag to track if account disabled dialog is showing
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupDeepLinkHandler();
  }
  
  /// Set up deep link handler for Live Activity navigation
  void _setupDeepLinkHandler() {
    const channel = MethodChannel('com.botleji/deep_link');
    channel.setMethodCallHandler((call) async {
      if (call.method == 'navigateToNavigation') {
        final args = call.arguments as Map<String, dynamic>?;
        final dropId = args?['dropId'] as String?;
        
        if (dropId != null && MyApp.navigatorKey.currentContext != null) {
          final context = MyApp.navigatorKey.currentContext!;
          final activeCollection = ref.read(navigationControllerProvider);
          
          if (activeCollection != null && activeCollection.dropId == dropId) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NavigationScreen(
                  destination: activeCollection.destination,
                  dropId: activeCollection.dropId,
                ),
              ),
            );
          }
        }
      }
    });
  }
  
  void _setupAccountDisabledCallback(WidgetRef ref) {
    final notificationService = ref.read(notificationServiceProvider);
    AppLogger.log('🔒 Main: Setting up account permanently disabled callback');
    notificationService.onAccountPermanentlyDisabled = () {
      AppLogger.log('🔒 ===== Main: Account permanently disabled callback triggered from WebSocket =====');
      _showAccountDisabledDialogWithRetry(ref);
      AppLogger.log('🔒 ============================================================');
    };
    AppLogger.log('🔒 Main: Account permanently disabled callback set up successfully');
    
    // Set up account deleted callback
    AppLogger.log('🗑️ Main: Setting up account deleted callback');
    notificationService.onAccountDeleted = () {
      AppLogger.log('🗑️ ===== Main: Account deleted callback triggered from WebSocket =====');
      _showAccountDeletedDialogWithRetry(ref);
      AppLogger.log('🗑️ ============================================================');
    };
    AppLogger.log('🗑️ Main: Account deleted callback set up successfully');
  }
  
  void _showAccountDisabledDialogWithRetry(WidgetRef ref, {int retryCount = 0}) {
    const maxRetries = 10;
    final context = MyApp.navigatorKey.currentContext;
    
    if (context != null) {
      AppLogger.log('🔒 Main: Context available, showing account disabled dialog NOW (attempt ${retryCount + 1})');
      try {
        _showAccountDisabledDialog(context, ref);
        AppLogger.log('🔒 Main: Dialog shown successfully');
      } catch (e) {
        AppLogger.log('❌ Error showing dialog: $e');
        if (retryCount < maxRetries) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _showAccountDisabledDialogWithRetry(ref, retryCount: retryCount + 1);
          });
        }
      }
    } else {
      AppLogger.log('⚠️ Main: Context not available (attempt ${retryCount + 1}/${maxRetries})');
      if (retryCount < maxRetries) {
        // Retry with exponential backoff
        final delay = Duration(milliseconds: 200 * (retryCount + 1));
        Future.delayed(delay, () {
          _showAccountDisabledDialogWithRetry(ref, retryCount: retryCount + 1);
        });
      } else {
        AppLogger.log('❌ Main: Failed to show dialog after $maxRetries attempts - context never became available');
        // Last resort: try to get context from build context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final fallbackContext = MyApp.navigatorKey.currentContext;
          if (fallbackContext != null) {
            AppLogger.log('🔒 Main: Got context on postFrameCallback, showing dialog');
            _showAccountDisabledDialog(fallbackContext, ref);
          }
        });
      }
    }
  }
  
  void _showAccountDeletedDialogWithRetry(WidgetRef ref, {int retryCount = 0}) {
    const maxRetries = 10;
    final context = MyApp.navigatorKey.currentContext;
    
    if (context != null) {
      AppLogger.log('🗑️ Main: Context available, showing account deleted dialog NOW (attempt ${retryCount + 1})');
      try {
        _showAccountDeletedDialog(context, ref);
        AppLogger.log('🗑️ Main: Dialog shown successfully');
      } catch (e) {
        AppLogger.log('❌ Error showing dialog: $e');
        if (retryCount < maxRetries) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _showAccountDeletedDialogWithRetry(ref, retryCount: retryCount + 1);
          });
        }
      }
    } else {
      AppLogger.log('⚠️ Main: Context not available (attempt ${retryCount + 1}/${maxRetries})');
      if (retryCount < maxRetries) {
        // Retry with exponential backoff
        final delay = Duration(milliseconds: 200 * (retryCount + 1));
        Future.delayed(delay, () {
          _showAccountDeletedDialogWithRetry(ref, retryCount: retryCount + 1);
        });
      } else {
        AppLogger.log('❌ Main: Failed to show dialog after $maxRetries attempts - context never became available');
        // Last resort: try to get context from build context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final fallbackContext = MyApp.navigatorKey.currentContext;
          if (fallbackContext != null) {
            AppLogger.log('🗑️ Main: Got context on postFrameCallback, showing dialog');
            _showAccountDeletedDialog(fallbackContext, ref);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Sync badge count with actual unread count when app comes to foreground
      AppLogger.log('🔔 App resumed - syncing badge count...');
      _syncBadgeCount();
      
      // Reconnect WebSocket notifications when app comes to foreground
      AppLogger.log('🔌 App resumed - reconnecting WebSocket notifications...');
      _reconnectWebSocketNotifications();
    }
  }

  Future<void> _syncBadgeCount() async {
    try {
      // Get actual unread count from backend
      final unreadCount = await NotificationService.getUnreadCount();
      AppLogger.log('🔔 App resumed - actual unread count: $unreadCount');
      // Update badge with actual count
      await LocalNotificationService().updateBadgeCount(unreadCount);
    } catch (e) {
      AppLogger.log('🔔 Error syncing badge count: $e');
      // If we can't get the count, at least clear it
      await LocalNotificationService().clearBadgeCount();
    }
  }

  Future<void> _reconnectWebSocketNotifications() async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        AppLogger.log('🔌 App resumed - No auth token, skipping WebSocket reconnection');
        return;
      }
      
      // Get notification service from provider and check if connected
      final notificationService = ref.read(notificationServiceProvider);
      AppLogger.log('🔌 App resumed - WebSocket connected: ${notificationService.isConnected}');
      
      // Reconnect if not connected
      if (!notificationService.isConnected) {
        AppLogger.log('🔌 App resumed - WebSocket not connected, reconnecting...');
        await notificationService.connect(token);
        AppLogger.log('🔌 App resumed - WebSocket reconnection attempted');
      } else {
        AppLogger.log('🔌 App resumed - WebSocket already connected');
      }
    } catch (e) {
      AppLogger.log('🔌 Error reconnecting WebSocket on app resume: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set up permanent account disabled callback (to show dialog when WebSocket notification received)
    // Use addPostFrameCallback to ensure ref is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAccountDisabledCallback(ref);
    });
    
    // Listen for 401 errors globally
    ref.listen(authNotifierProvider, (previous, next) {
      AppLogger.log('🚪 Main: Auth state changed - Previous: ${previous?.value?.id}, Next: ${next.value?.id}');

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!context.mounted) return;

        // Check if user is permanently disabled (logged in but account is permanently locked)
        final currentUser = next.value;
        if (currentUser != null && 
            currentUser.isAccountLocked && 
            currentUser.accountLockedUntil == null) {
          // User is permanently disabled - show account disabled dialog
          // Use a longer delay to ensure context is fully mounted
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              _showAccountDisabledDialog(context, ref);
            }
          });
          return;
        }

        final pendingReason = LocalNotificationService().getPendingForceLogoutReason();
        if (pendingReason != null) {
          _showForceLogoutDialog(context, pendingReason);
          return;
        }

        final authNotifier = ref.read(authNotifierProvider.notifier);
        final authPendingReason = authNotifier.getPendingForceLogoutReason();
        if (authPendingReason != null) {
          _showForceLogoutDialog(context, authPendingReason);
        }
      });

      if (next.hasError) {
        final error = next.error;
        if (error != null && error.toString().contains('401')) {
          // Check if user is permanently disabled before showing session expired
          // Try to get current user from auth state
          final currentUser = ref.read(authNotifierProvider).value;
          if (currentUser != null && 
              currentUser.isAccountLocked && 
              currentUser.accountLockedUntil == null) {
            // User is permanently disabled - show account disabled dialog instead
            _showAccountDisabledDialog(context, ref);
            return;
          }
          
          // TEMPORARILY DISABLED FOR TESTING - Session expired dialog
          // showDialog(
          //   context: context,
          //   barrierDismissible: false,
          //   builder: (BuildContext context) {
          //     final l10n = AppLocalizations.of(context);
          //     return AlertDialog(
          //       title: Text(l10n.sessionExpired),
          //       content: Text(l10n.sessionExpiredMessage),
          //       actions: [
          //         TextButton(
          //           onPressed: () {
          //             Navigator.of(context).pop();
          //             Navigator.of(context).pushNamedAndRemoveUntil(
          //               '/login',
          //               (route) => false,
          //             );
          //           },
          //           child: Text(l10n.login),
          //         ),
          //       ],
          //     );
          //   },
          // );
          print('⚠️ Session expired detected but dialog disabled for testing');
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationController = ref.read(navigationControllerProvider.notifier);
      navigationController.debugCheckSavedCollection();
    });

    // Log current ColorScheme whenever theme changes
    ref.listen(themeControllerProvider, (previous, next) {
      // Defer to next frame to ensure theme has been applied
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = MyApp.navigatorKey.currentContext ?? context;
        if (!mounted || ctx == null) return;
        _dumpActiveColorScheme(ctx, label: 'Theme changed to ${next.name.toUpperCase()}');
      });
    });

    // Initial dump after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dumpActiveColorScheme(context, label: 'Initial theme');
    });

    // Removed splash-on-resume behavior per request

    final currentLocale = ref.watch(localizationControllerProvider);
    
    return MaterialApp(
      title: 'Bottleji',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeControllerProvider),
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocalizationController.supportedLocales,
      locale: currentLocale,
      initialRoute: '/splash',
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/main': (context) => const MainAppScreen(),
        '/login': (context) => LoginScreen(key: UniqueKey()), // Use UniqueKey to ensure fresh instance
        '/home': (context) => const HomeScreen(),
        '/profile-setup': (context) => ProfileSetupScreen(
          email: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['email'] ?? '',
        ),
        '/history': (context) => const HistoryScreen(),
        '/navigation': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final dropId = args?['dropId'] as String?;
          final activeCollection = ref.read(navigationControllerProvider);
          
          if (activeCollection != null) {
            return NavigationScreen(
              destination: activeCollection.destination,
              dropId: activeCollection.dropId,
            );
          } else if (dropId != null) {
            // Try to restore collection from backend
            // For now, navigate to home if collection not found
            return const HomeScreen();
          }
          return const HomeScreen();
        },
      },
      onGenerateRoute: (settings) {
        // Handle deep links from Live Activity (botleji://navigation?dropId=xxx)
        if (settings.name?.startsWith('botleji://') == true) {
          final uri = Uri.parse(settings.name!);
          if (uri.host == 'navigation') {
            final dropId = uri.queryParameters['dropId'];
            
            if (dropId != null) {
              final activeCollection = ref.read(navigationControllerProvider);
              if (activeCollection != null && activeCollection.dropId == dropId) {
                return MaterialPageRoute(
                  builder: (context) => NavigationScreen(
                    destination: activeCollection.destination,
                    dropId: activeCollection.dropId,
                  ),
                );
              }
            }
          }
        }
        return null;
      },
    );
  }


  void _showAccountDeletedDialog(BuildContext context, WidgetRef ref) {
    // Prevent showing multiple dialogs
    if (_isAccountDisabledDialogShowing) {
      AppLogger.log('🗑️ Account deleted dialog already showing, skipping');
      return;
    }
    
    // Double-check context is still valid
    if (!context.mounted) {
      AppLogger.log('⚠️ Context is not mounted, cannot show dialog');
      return;
    }
    
    _isAccountDisabledDialogShowing = true;
    AppLogger.log('🗑️ Showing account deleted dialog...');
    
    try {
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false, // Make it non-dismissible to ensure user sees it
        useRootNavigator: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            title: Text(l10n.accountDeleted),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accountDeletedMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        l10n.supportEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  _isAccountDisabledDialogShowing = false;
                  
                  // After user acknowledges, invalidate session on backend, then show session expired and logout
                  AppLogger.log('🗑️ User acknowledged account deleted dialog, invalidating session and logging out');
                  
                  // Invalidate session on backend first
                  try {
                    final authNotifier = ref.read(authNotifierProvider.notifier);
                    await authNotifier.invalidateSession();
                    AppLogger.log('🗑️ Session invalidated on backend');
                  } catch (e) {
                    AppLogger.log('⚠️ Error invalidating session: $e');
                    // Continue with logout even if invalidation fails
                  }
                  
                  // Show session expired dialog
                  if (context.mounted) {
                    final l10n = AppLocalizations.of(context);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      useRootNavigator: true,
                      builder: (BuildContext sessionDialogContext) {
                        return AlertDialog(
                          title: Text(l10n.sessionExpired),
                          content: Text(l10n.sessionExpiredMessage),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                Navigator.of(sessionDialogContext).pop();
                                // Force logout
                                await ref.read(authNotifierProvider.notifier).logout(ref);
                                if (context.mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                    (route) => false,
                                  );
                                }
                              },
                              child: Text(l10n.login),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text(l10n.ok),
              ),
            ],
          );
        },
      ).then((_) {
        AppLogger.log('🗑️ Account deleted dialog closed');
      }).catchError((error) {
        AppLogger.log('❌ Error showing account deleted dialog: $error');
        _isAccountDisabledDialogShowing = false;
      });
    } catch (e) {
      AppLogger.log('❌ Exception showing account deleted dialog: $e');
      _isAccountDisabledDialogShowing = false;
      rethrow;
    }
  }

  void _showAccountDisabledDialog(BuildContext context, WidgetRef ref) {
    // Prevent showing multiple dialogs
    if (_isAccountDisabledDialogShowing) {
      AppLogger.log('🔒 Account disabled dialog already showing, skipping');
      return;
    }
    
    // Double-check context is still valid
    if (!context.mounted) {
      AppLogger.log('⚠️ Context is not mounted, cannot show dialog');
      return;
    }
    
    _isAccountDisabledDialogShowing = true;
    AppLogger.log('🔒 Showing account disabled dialog...');
    
    try {
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        barrierDismissible: false, // Make it non-dismissible to ensure user sees it
        useRootNavigator: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
          icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          title: Text(l10n.accountDisabled),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.accountDisabledMessage,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      l10n.supportEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                _isAccountDisabledDialogShowing = false;
                
                // After user acknowledges, invalidate session on backend, then show session expired and logout
                AppLogger.log('🔒 User acknowledged account disabled dialog, invalidating session and logging out');
                
                // Invalidate session on backend first
                try {
                  final authNotifier = ref.read(authNotifierProvider.notifier);
                  await authNotifier.invalidateSession();
                  AppLogger.log('🔒 Session invalidated on backend');
                } catch (e) {
                  AppLogger.log('⚠️ Error invalidating session: $e');
                  // Continue with logout even if invalidation fails
                }
                
                // Show session expired dialog
                if (context.mounted) {
                  final l10n = AppLocalizations.of(context);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    useRootNavigator: true,
                    builder: (BuildContext sessionDialogContext) {
                      return AlertDialog(
                        title: Text(l10n.sessionExpired),
                        content: Text(l10n.sessionExpiredMessage),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              Navigator.of(sessionDialogContext).pop();
                              // Force logout
                              await ref.read(authNotifierProvider.notifier).logout(ref);
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            child: Text(l10n.login),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    ).then((_) {
      AppLogger.log('🔒 Account disabled dialog closed');
    }).catchError((error) {
      AppLogger.log('❌ Error showing account disabled dialog: $error');
      _isAccountDisabledDialogShowing = false;
    });
    } catch (e) {
      AppLogger.log('❌ Exception showing account disabled dialog: $e');
      _isAccountDisabledDialogShowing = false;
      rethrow;
    }
  }

  void _showForceLogoutDialog(BuildContext context, String reason) {
    if (MyApp.navigatorKey.currentContext != null) {
      _showDialogWithContext(MyApp.navigatorKey.currentContext!, reason);
      return;
    }

    if (!context.mounted) {
      return;
    }

    _showDialogWithContext(context, reason);
  }

  void _showDialogWithContext(BuildContext context, String reason) {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (BuildContext dialogContext) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
            title: Text(l10n.accountDeleted),
            content: Text(
              '${l10n.accountDeletedMessage}\n\n${l10n.reason}: $reason\n\n${l10n.youWillBeRedirectedToLoginScreen}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  final container = ProviderScope.containerOf(context);
                  final authNotifier = container.read(authNotifierProvider.notifier);
                  authNotifier.executeForceLogout();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: Text(l10n.ok),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  final container = ProviderScope.containerOf(context);
                  final authNotifier = container.read(authNotifierProvider.notifier);
                  authNotifier.executeForceLogout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseEmailSupport),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: Text(l10n.contactSupport),
              ),
            ],
          );
        },
      );
    } catch (e) {
      AppLogger.log('Error showing dialog: $e');
    }
  }

}

extension on _MyAppState {
  void _dumpActiveColorScheme(BuildContext context, {String label = 'ColorScheme'}) {
    try {
      final s = Theme.of(context).colorScheme;
      String hex(Color c) => '#'
          '${c.alpha.toRadixString(16).padLeft(2, '0')}'
          '${c.red.toRadixString(16).padLeft(2, '0')}'
          '${c.green.toRadixString(16).padLeft(2, '0')}'
          '${c.blue.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
      // Compact, thesis-ready output
      debugPrint('=== $label ===');
      debugPrint('primary: ${hex(s.primary)} | onPrimary: ${hex(s.onPrimary)} | primaryContainer: ${hex(s.primaryContainer)} | onPrimaryContainer: ${hex(s.onPrimaryContainer)}');
      debugPrint('secondary: ${hex(s.secondary)} | onSecondary: ${hex(s.onSecondary)} | secondaryContainer: ${hex(s.secondaryContainer)} | onSecondaryContainer: ${hex(s.onSecondaryContainer)}');
      debugPrint('tertiary: ${hex(s.tertiary)} | onTertiary: ${hex(s.onTertiary)} | tertiaryContainer: ${hex(s.tertiaryContainer)} | onTertiaryContainer: ${hex(s.onTertiaryContainer)}');
      debugPrint('error: ${hex(s.error)} | onError: ${hex(s.onError)} | errorContainer: ${hex(s.errorContainer)} | onErrorContainer: ${hex(s.onErrorContainer)}');
      debugPrint('background: ${hex(s.background)} | onBackground: ${hex(s.onBackground)} | surface: ${hex(s.surface)} | onSurface: ${hex(s.onSurface)}');
      debugPrint('surfaceVariant: ${hex(s.surfaceVariant)} | onSurfaceVariant: ${hex(s.onSurfaceVariant)} | outline: ${hex(s.outline)} | outlineVariant: ${hex(s.outlineVariant)}');
      debugPrint('inverseSurface: ${hex(s.inverseSurface)} | onInverseSurface: ${hex(s.onInverseSurface)} | inversePrimary: ${hex(s.inversePrimary)} | surfaceTint: ${hex(s.surfaceTint)}');
    } catch (e) {
      debugPrint('Failed to dump ColorScheme: $e');
    }
  }
}

// Removed ResumeSplashScreen widget per request

class MainAppScreen extends ConsumerStatefulWidget {
  const MainAppScreen({super.key});

  @override
  ConsumerState<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends ConsumerState<MainAppScreen> {
  static Widget? _cachedHomeScreen;
  bool _hasCreatedHomeScreen = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userMode = ref.watch(userModeControllerProvider);
    final navigationController = ref.watch(navigationControllerProvider.notifier);
    
    // Check if all providers are ready
    final isAuthReady = authState.hasValue;
    final isUserModeReady = userMode.hasValue;
    // Don't wait for navigationController - it's not critical for initial load
    final isNavigationReady = !navigationController.isLoading;
    
    AppLogger.log('🔄 MainAppScreen rebuild - Auth: $isAuthReady, UserMode: $isUserModeReady, Navigation: $isNavigationReady');
    AppLogger.log('🔄 Auth state: ${authState.when(data: (user) => user?.id, loading: () => 'loading', error: (_, __) => 'error')}');
    
    // Show loading screen only for critical providers (auth and userMode)
    // Navigation controller can load in the background
    if (!isAuthReady || !isUserModeReady) {
      AppLogger.log('⏳ Showing loading screen - Auth: $isAuthReady, UserMode: $isUserModeReady');
      return Scaffold(
        backgroundColor: const Color(0xFF00695C),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo_v2.png',
                height: 120,
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                _getLoadingMessage(authState, userMode, navigationController),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // All providers are ready, now handle the logic
    return authState.when(
      data: (user) {
        if (user == null) {
          return LoginScreen(key: UniqueKey()); // Use UniqueKey to ensure fresh instance
        }

        if (!user.isProfileComplete) {
          return ProfileSetupScreen(
            email: user.email,
            isNewUserSetup: true,
          );
        }

        // All conditions met, return HomeScreen
        AppLogger.log('🏠 MainAppScreen: All providers ready!');
        
        // Initialize global Live Activity manager
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(globalLiveActivityManagerProvider);
        });
        
        // Ensure FCM token is saved when user is logged in (in case token changed)
        // This runs on app start AND app restart
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            final fcmService = FCMService();
            
            // If FCM is not initialized yet, try to initialize it
            // (user might have already granted permissions before)
            if (!fcmService.initialized) {
              AppLogger.log('🔔 FCM not initialized yet, initializing on app start...');
              try {
                await fcmService.initialize();
                AppLogger.log('✅ FCM initialized on app start');
              } catch (e) {
                AppLogger.log('⚠️ Could not initialize FCM on app start: $e');
                // Continue anyway - FCM might not be available
              }
            }
            
            // If FCM is now initialized, save the current token to backend
            if (fcmService.initialized) {
              AppLogger.log('🔔 Saving FCM token to backend on app start/restart...');
              await fcmService.saveTokenToBackend();
              AppLogger.log('✅ FCM token saved to backend');
            } else {
              AppLogger.log('ℹ️ FCM not initialized - token will be saved when FCM initializes');
            }
          } catch (e) {
            AppLogger.log('⚠️ Error ensuring FCM token is saved: $e');
          }
        });
        
        // Only create HomeScreen once
        if (!_hasCreatedHomeScreen) {
          AppLogger.log('🏠 MainAppScreen: Creating HomeScreen instance for the first time');
          _cachedHomeScreen = const HomeScreen();
          _hasCreatedHomeScreen = true;
        } else {
          AppLogger.log('🏠 MainAppScreen: Reusing cached HomeScreen instance');
        }
        
        return Stack(
          children: [
            _cachedHomeScreen!,
            // Collection Success Popup
            Consumer(
              builder: (context, ref, child) {
                final collectionSuccessState = ref.watch(collectionSuccessProvider);
                
                if (collectionSuccessState.showPopup) {
                  AppLogger.log('🎉 MainApp: Rendering CollectionSuccessPopup with ${collectionSuccessState.pointsAwarded} points');
                  return CollectionSuccessPopup(
                    pointsAwarded: collectionSuccessState.pointsAwarded,
                    tierName: collectionSuccessState.tierName,
                    currentTier: collectionSuccessState.currentTier,
                    totalPoints: collectionSuccessState.totalPoints,
                    tierUpgraded: collectionSuccessState.tierUpgraded,
                    onDismiss: () {
                      ref.read(collectionSuccessProvider.notifier).dismissPopup();
                    },
                  );
                } else {
                  AppLogger.log('🎉 MainApp: Popup not showing, showPopup: ${collectionSuccessState.showPopup}');
                }
                
                return const SizedBox.shrink();
              },
            ),
          ],
        );
      },
      loading: () {
        // This should not be reached due to the check above, but keeping for safety
        return Scaffold(
          backgroundColor: const Color(0xFF00695C),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_v2.png',
                  height: 120,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) {
        return const LoginScreen();
      },
    );
  }

  String _getLoadingMessage(AsyncValue authState, AsyncValue userMode, NavigationController navigationController) {
    if (!authState.hasValue) {
      return 'Loading authentication...';
    } else if (!userMode.hasValue) {
      return 'Loading user mode...';
    } else if (navigationController.isLoading) {
      return 'Loading collection state...';
    } else {
      return 'Loading...';
    }
  }
}
