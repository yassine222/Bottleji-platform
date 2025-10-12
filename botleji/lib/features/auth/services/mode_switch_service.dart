import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/auth/presentation/screens/mode_switch_splash_screen.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/auth/models/user.dart';

class ModeSwitchService {
  // Prevent multiple splash screens
  static bool _isInSplashScreen = false;

  static Future<void> switchMode(
    BuildContext context,
    WidgetRef ref,
    UserMode newMode, {
    bool skipSplash = false,
  }) async {
    try {
      print('🔄 ModeSwitchService: Starting mode switch to: ${newMode.name} (skipSplash: $skipSplash)');

      if (_isInSplashScreen) {
        print('🔄 ModeSwitchService: Splash screen already in progress, skipping mode switch');
        return;
      }

      // Get current user info for debugging
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;
      print('🔄 ModeSwitchService: Current user roles: ${user?.roles}');
      print('🔄 ModeSwitchService: Current user application status: ${user?.collectorApplicationStatus}');

      // Set the new mode BEFORE showing splash screen
      print('🔄 ModeSwitchService: Setting new mode: ${newMode.name}');
      await ref.read(userModeControllerProvider.notifier).setMode(newMode);
      print('🔄 ModeSwitchService: Mode set successfully');

      if (skipSplash) {
        print('🔄 ModeSwitchService: Skipping splash screen, mode switch completed');
        if (context.mounted) Navigator.of(context).pop(); // Close drawer/dialog if any
        return;
      }

      print('🔄 ModeSwitchService: Showing splash screen...');
      _isInSplashScreen = true;

      await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return ModeSwitchSplashScreen(
              targetMode: newMode,
              onTransitionComplete: () async {
                print('🔄 ModeSwitchService: Splash screen completed');

                _isInSplashScreen = false;

                if (context.mounted) {
                  Navigator.of(context).pop(); // Close splash screen
                  await Future.delayed(const Duration(milliseconds: 100));
                  
                  // Only invalidate if the widget is still mounted
                  if (context.mounted) {
                    try {
                      ref.invalidate(userModeControllerProvider);
                    } catch (e) {
                      print('⚠️ ModeSwitchService: Could not invalidate provider (widget disposed): $e');
                    }
                  }
                }

                print('🔄 ModeSwitchService: Mode switch completed successfully');
              },
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          opaque: false,
          barrierDismissible: false,
        ),
      );

      print('🔄 ModeSwitchService: Navigator.push completed');
    } catch (e) {
      print('❌ ModeSwitchService: Error during mode switch: $e');
      // Fallback: set mode directly
      await ref.read(userModeControllerProvider.notifier).setMode(newMode);
    }
  }

  static void resetRestartFlag() {
    _isInSplashScreen = false;
  }
}
