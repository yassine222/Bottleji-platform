import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/core/theme/app_theme.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/auth/presentation/screens/login_screen.dart';
import 'package:botleji/features/home/presentation/screens/home_screen.dart';
import 'package:botleji/features/history/presentation/screens/history_screen.dart';
import 'package:botleji/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:botleji/core/controllers/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/core/services/local_notification_service.dart';
import 'package:botleji/features/auth/services/mode_switch_service.dart';
import 'package:botleji/features/splash/presentation/screens/splash_screen.dart';
import 'package:botleji/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:botleji/features/onboarding/presentation/screens/permissions_screen.dart';
import 'package:botleji/features/rewards/presentation/providers/collection_success_provider.dart';
import 'package:botleji/features/rewards/presentation/widgets/collection_success_popup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();

  // Reset mode switch splash screen flag on app startup
  ModeSwitchService.resetRestartFlag();

  // Initialize local notification service
  await LocalNotificationService().initialize();

  // Set up notification tap handling
  LocalNotificationService().handleNotificationTap = (payload) async {
    print('🔔 Main: Notification tapped with payload: $payload');
    if (payload != null && payload.startsWith('force_logout:')) {
      final reason = payload.substring('force_logout:'.length);
      print('🔔 Main: Force logout notification tapped, reason: $reason');

      // Store the reason to show dialog when app is ready
      LocalNotificationService().showForceLogoutDialog(reason);
    }
  };

  // Set up global error handling for 401 errors
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Global error: ${details.exception}');

    // Check if it's a 401 error
    if (details.exception.toString().contains('401')) {
      print('Global 401 error detected');
      // This will be handled by the auth provider
    }
  };

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    // Wait longer for Firebase Auth to be ready
    print('Waiting for Firebase Auth to be ready...');
    await Future.delayed(const Duration(milliseconds: 2000));
    print('Firebase Auth should be ready now');
  } catch (e, stackTrace) {
    print('Error initializing Firebase: $e');
    print('Stack trace: $stackTrace');
    print('Continuing without Firebase...');
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

class _MyAppState extends ConsumerState<MyApp> {

  @override
  Widget build(BuildContext context) {
    // Listen for 401 errors globally
    ref.listen(authNotifierProvider, (previous, next) {
      print('🚪 Main: Auth state changed - Previous: ${previous?.value?.id}, Next: ${next.value?.id}');

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!context.mounted) return;

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
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Session Expired'),
                content: const Text('Your session has expired. Please login again to continue.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    },
                    child: const Text('Login'),
                  ),
                ],
              );
            },
          );
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigationController = ref.read(navigationControllerProvider.notifier);
      navigationController.debugCheckSavedCollection();
    });

    // Removed splash-on-resume behavior per request

    return MaterialApp(
      title: 'Bottleji',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeControllerProvider),
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      initialRoute: '/splash',
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/main': (context) => const MainAppScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile-setup': (context) => ProfileSetupScreen(
          email: (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?)?['email'] ?? '',
        ),
        '/history': (context) => const HistoryScreen(),
      },
    );
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
          return AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
            title: const Text('Account Deleted'),
            content: Text(
              'Your account has been deleted by an administrator.\n\nReason: $reason\n\n'
              'If you believe this is a mistake, please contact our support team:\n\n'
              '📧 Email: support@bottleji.com\n'
              '📱 Support Hours: 9 AM - 6 PM (GMT+1)\n\n'
              'You will be redirected to the login screen.',
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
                child: const Text('OK'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  final container = ProviderScope.containerOf(context);
                  final authNotifier = container.read(authNotifierProvider.notifier);
                  authNotifier.executeForceLogout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please email support@bottleji.com for assistance'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                },
                child: const Text('Contact Support'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing dialog: $e');
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
    final isNavigationReady = !navigationController.isLoading;
    
    print('🔄 MainAppScreen rebuild - Auth: $isAuthReady, UserMode: $isUserModeReady, Navigation: $isNavigationReady');
    print('🔄 Auth state: ${authState.when(data: (user) => user?.id, loading: () => 'loading', error: (_, __) => 'error')}');
    
    // Show loading screen until ALL providers are ready
    if (!isAuthReady || !isUserModeReady || !isNavigationReady) {
      print('⏳ Showing loading screen - Auth: $isAuthReady, UserMode: $isUserModeReady, Navigation: $isNavigationReady');
      return Scaffold(
        backgroundColor: const Color(0xFF00695C),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
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
          return const LoginScreen();
        }

        if (!user.isProfileComplete) {
          return ProfileSetupScreen(
            email: user.email,
            isNewUserSetup: true,
          );
        }

        // All conditions met, return HomeScreen
        print('🏠 MainAppScreen: All providers ready!');
        
        // Only create HomeScreen once
        if (!_hasCreatedHomeScreen) {
          print('🏠 MainAppScreen: Creating HomeScreen instance for the first time');
          _cachedHomeScreen = const HomeScreen();
          _hasCreatedHomeScreen = true;
        } else {
          print('🏠 MainAppScreen: Reusing cached HomeScreen instance');
        }
        
        return Stack(
          children: [
            _cachedHomeScreen!,
            // Collection Success Popup
            Consumer(
              builder: (context, ref, child) {
                final collectionSuccessState = ref.watch(collectionSuccessProvider);
                
                if (collectionSuccessState.showPopup) {
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
                  'assets/images/logo.png',
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
