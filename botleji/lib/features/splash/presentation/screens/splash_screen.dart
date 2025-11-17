import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:botleji/core/utils/logger.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';

const appGreenColor = Color(0xFF00695C);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Start animation and wait for it to complete before checking navigation
    _startAnimationAndCheck();
  }

  Future<void> _startAnimationAndCheck() async {
    // Start the animation
    await _animationController.forward();
    
    // Wait for animation to fully complete and be visible
    // Animation duration is 1500ms, wait additional 1500ms for users to appreciate it
    // Total minimum display: 3 seconds
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Now check and navigate
    if (mounted) {
      _checkFirstTimeUser();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    // Animation has already completed and been displayed
    // No additional delay needed here - minimum display time already ensured in _startAnimationAndCheck

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;

    // Check if user is already authenticated
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState.hasValue && authState.value != null;

    if (isFirstTime && !isAuthenticated) {
      // Only show onboarding for unauthenticated first-time users
      Navigator.of(context).pushReplacementNamed('/onboarding');
      return;
    }

    // Ensure we don't show onboarding again for authenticated users
    if (isFirstTime && isAuthenticated) {
      await prefs.setBool('is_first_time', false);
    }

    // Wait for user mode to be loaded before navigating to main app
    await _waitForUserModeAndNavigate();
  }

  Future<void> _waitForUserModeAndNavigate() async {
    // Wait for both auth and user mode to be ready
    final authState = ref.read(authNotifierProvider);
    final userMode = ref.read(userModeControllerProvider);
    
    // If auth state is loaded and there's no logged-in user, go directly to login
    if (authState.hasValue && authState.value == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    
    AppLogger.log('⏳ Splash: Checking auth and user mode...');
    AppLogger.log('⏳ Splash: Auth state: ${authState.hasValue} (${authState.hasError ? 'error' : authState.isLoading ? 'loading' : 'ready'})');
    AppLogger.log('⏳ Splash: UserMode state: ${userMode.hasValue} (${userMode.hasError ? 'error' : userMode.isLoading ? 'loading' : 'ready'})');
    
    // If both are already loaded, navigate immediately
    if (authState.hasValue && authState.value != null && userMode.hasValue) {
      AppLogger.log('✅ Splash: Both auth and user mode already loaded, navigating to main');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
      return;
    }
    
    // Check for errors - navigate anyway if there are errors
    if (authState.hasError || userMode.hasError) {
      AppLogger.log('⚠️ Splash: Error detected, navigating anyway');
      AppLogger.log('⚠️ Splash: Auth error: ${authState.hasError}, UserMode error: ${userMode.hasError}');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
      return;
    }
    
    // Otherwise, wait for both to load with polling
    AppLogger.log('⏳ Splash: Waiting for auth and user mode to load...');
    
    // Listen to both auth and user mode changes
    bool hasNavigated = false;
    
    ref.listen(authNotifierProvider, (previous, next) {
      final currentUserMode = ref.read(userModeControllerProvider);
      AppLogger.log('🔄 Splash: Auth changed - hasValue: ${next.hasValue}, UserMode hasValue: ${currentUserMode.hasValue}');
      
      if (mounted && !hasNavigated && next.hasValue && next.value == null) {
        hasNavigated = true;
        AppLogger.log('✅ Splash: Auth loaded with no user (via auth listener), navigating to login');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else if (mounted && !hasNavigated && next.hasValue && currentUserMode.hasValue) {
        hasNavigated = true;
        AppLogger.log('✅ Splash: Auth and user mode loaded (via auth listener), navigating to main');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else if (mounted && !hasNavigated && next.hasError) {
        hasNavigated = true;
        AppLogger.log('⚠️ Splash: Auth error detected, navigating anyway');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    });
    
    ref.listen(userModeControllerProvider, (previous, next) {
      final currentAuthState = ref.read(authNotifierProvider);
      AppLogger.log('🔄 Splash: UserMode changed - hasValue: ${next.hasValue}, Auth hasValue: ${currentAuthState.hasValue}');
      
      if (mounted && !hasNavigated && currentAuthState.hasValue && currentAuthState.value == null) {
        hasNavigated = true;
        AppLogger.log('✅ Splash: Auth loaded with no user (via userMode listener), navigating to login');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else if (mounted && !hasNavigated && next.hasValue && currentAuthState.hasValue && currentAuthState.value != null) {
        hasNavigated = true;
        AppLogger.log('✅ Splash: Auth and user mode loaded (via userMode listener), navigating to main');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      } else if (mounted && !hasNavigated && next.hasError) {
        hasNavigated = true;
        AppLogger.log('⚠️ Splash: UserMode error detected, navigating anyway');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    });
    
    // Poll every 500ms to check if providers are ready (for faster navigation)
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted || hasNavigated) break;
      
      final currentAuthState = ref.read(authNotifierProvider);
      final currentUserMode = ref.read(userModeControllerProvider);
      
      if (currentAuthState.hasValue && currentAuthState.value == null) {
        hasNavigated = true;
        AppLogger.log('✅ Splash: Auth loaded with no user (via polling), navigating to login');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        break;
      }
      
      if (currentAuthState.hasValue && currentAuthState.value != null && currentUserMode.hasValue) {
        hasNavigated = true;
        AppLogger.log('✅ Splash: Providers ready after polling, navigating to main');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
        break;
      }
      
      if (currentAuthState.hasError || currentUserMode.hasError) {
        hasNavigated = true;
        AppLogger.log('⚠️ Splash: Error detected during polling, navigating anyway');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
        break;
      }
    }
    
    // Final fallback: navigate after maximum wait time (reduced from 5s to 3s)
    if (mounted && !hasNavigated) {
      AppLogger.log('⏰ Splash: Timeout waiting for auth/user mode, navigating anyway');
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appGreenColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appGreenColor,
              appGreenColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with animations
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          // App Logo
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // App Name
                          const Text(
                            'Bottleji',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Tagline
                          const Text(
                            'Sustainable Waste Management',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 80),
              
              // Loading indicator
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}