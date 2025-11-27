import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/l10n/app_localizations.dart';
import 'dart:async'; // Added for Timer


class ModeSwitchSplashScreen extends ConsumerStatefulWidget {
  final UserMode targetMode;
  final VoidCallback onTransitionComplete;

  const ModeSwitchSplashScreen({
    super.key,
    required this.targetMode,
    required this.onTransitionComplete,
  });

  @override
  ConsumerState<ModeSwitchSplashScreen> createState() => _ModeSwitchSplashScreenState();
}

class _ModeSwitchSplashScreenState extends ConsumerState<ModeSwitchSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Add flag to prevent multiple restarts
  bool _hasCompleted = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    print('🔄 SplashScreen: initState called for ${widget.targetMode.name}');
    
    // Initialize only fade controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    print('🔄 SplashScreen: Controllers initialized, starting animations...');
    
    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    try {
      print('🔄 SplashScreen: Starting animations for ${widget.targetMode.name}');
      
      // Start safety timer with shorter duration
      _safetyTimer = Timer(const Duration(seconds: 3), () {
        print('🔄 SplashScreen: Safety timeout reached');
        if (mounted && !_hasCompleted) {
          print('🔄 SplashScreen: Safety timeout - calling completion callback');
          _hasCompleted = true;
          widget.onTransitionComplete();
        } else {
          print('🔄 SplashScreen: Safety timeout - already completed or not mounted');
        }
      });
      
      print('🔄 SplashScreen: Starting fade in...');
      await _fadeController.forward();
      print('🔄 SplashScreen: Fade in completed');
      
      print('🔄 SplashScreen: Waiting 300ms...');
      await Future.delayed(const Duration(milliseconds: 300));
      print('🔄 SplashScreen: 300ms wait completed');
      
      print('🔄 SplashScreen: Waiting 500ms to show mode...');
      await Future.delayed(const Duration(milliseconds: 500));
      print('🔄 SplashScreen: 500ms wait completed');
      
      print('🔄 SplashScreen: Starting fade out...');
      await _fadeController.reverse();
      print('🔄 SplashScreen: Fade out completed');
      
      print('🔄 SplashScreen: Animations completed, calling completion callback');
      
      // Cancel safety timer since we completed normally
      _safetyTimer?.cancel();
      print('🔄 SplashScreen: Safety timer cancelled');
      
      // Ensure we're still mounted and haven't completed yet
      if (mounted && !_hasCompleted) {
        print('🔄 SplashScreen: Calling completion callback (normal flow)');
        _hasCompleted = true;
        widget.onTransitionComplete();
      } else {
        print('🔄 SplashScreen: Skipping completion callback - mounted: $mounted, completed: $_hasCompleted');
      }
    } catch (e) {
      print('❌ SplashScreen: Error in animation: $e');
      
      // Cancel safety timer since we're handling completion
      _safetyTimer?.cancel();
      print('🔄 SplashScreen: Safety timer cancelled due to error');
      
      // Ensure callback is called even if animation fails
      if (mounted && !_hasCompleted) {
        print('🔄 SplashScreen: Calling completion callback (error flow)');
        _hasCompleted = true;
        widget.onTransitionComplete();
      } else {
        print('🔄 SplashScreen: Skipping completion callback due to error - mounted: $mounted, completed: $_hasCompleted');
      }
    }
  }

  @override
  void dispose() {
    print('🔄 SplashScreen: dispose called');
    _safetyTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  String _getModeTitle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (widget.targetMode) {
      case UserMode.household:
        return l10n.householdMode;
      case UserMode.collector:
        return l10n.collectorMode;
    }
  }

  String _getModeDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (widget.targetMode) {
      case UserMode.household:
        return l10n.householdModeDescription;
      case UserMode.collector:
        return l10n.collectorModeDescription;
    }
  }

  String _getModeImagePath() {
    switch (widget.targetMode) {
      case UserMode.household:
        return 'assets/images/household_mode.png';
      case UserMode.collector:
        return 'assets/images/collector_mode.png';
    }
  }

  Color _getModeColor() {
    switch (widget.targetMode) {
      case UserMode.household:
        return const Color(0xFF00695C);
      case UserMode.collector:
        return const Color(0xFF00695C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getModeColor(),
      body: GestureDetector(
        onTap: () {
          print('🔄 SplashScreen: Manual tap detected, forcing completion');
          if (!_hasCompleted) {
            _hasCompleted = true;
            _safetyTimer?.cancel();
            _fadeController.stop(); // Stop any ongoing animations
            widget.onTransitionComplete();
          }
        },
        onDoubleTap: () {
          print('🔄 SplashScreen: Double tap detected, forcing immediate completion');
          if (!_hasCompleted) {
            _hasCompleted = true;
            _safetyTimer?.cancel();
            _fadeController.stop(); // Stop any ongoing animations
            widget.onTransitionComplete();
          }
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _getModeColor(),
                  _getModeColor().withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mode-specific image
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        _getModeImagePath(),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image fails to load
                          return Icon(
                            widget.targetMode == UserMode.household
                                ? Icons.home
                                : Icons.recycling,
                            size: 80,
                            color: _getModeColor(),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Mode title
                  Text(
                    _getModeTitle(context),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mode description
                  Text(
                    _getModeDescription(context),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Loading indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tap to skip indicator
                  Text(
                    'Tap to skip',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 