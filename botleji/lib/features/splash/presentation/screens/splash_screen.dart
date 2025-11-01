import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    _animationController.forward();
    _checkFirstTimeUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTimeUser() async {
    // Wait for minimum splash duration
    await Future.delayed(const Duration(milliseconds: 1500));

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
    
    // If both are already loaded, navigate immediately
    if (authState.hasValue && userMode.hasValue) {
      print('✅ Splash: Both auth and user mode already loaded, navigating to main');
      Navigator.of(context).pushReplacementNamed('/main');
      return;
    }
    
    // Otherwise, wait for both to load
    print('⏳ Splash: Waiting for auth and user mode to load...');
    print('⏳ Splash: Auth ready: ${authState.hasValue}, UserMode ready: ${userMode.hasValue}');
    
    // Listen to both auth and user mode changes
    bool hasNavigated = false;
    
    ref.listen(authNotifierProvider, (previous, next) {
      if (mounted && !hasNavigated && next.hasValue && userMode.hasValue) {
        hasNavigated = true;
        print('✅ Splash: Auth and user mode loaded, navigating to main');
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
    
    ref.listen(userModeControllerProvider, (previous, next) {
      if (mounted && !hasNavigated && next.hasValue && authState.hasValue) {
        hasNavigated = true;
        print('✅ Splash: Auth and user mode loaded, navigating to main');
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
    
    // Fallback: navigate after maximum wait time
    await Future.delayed(const Duration(seconds: 5));
    if (mounted && !hasNavigated) {
      print('⏰ Splash: Timeout waiting for auth/user mode, navigating anyway');
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