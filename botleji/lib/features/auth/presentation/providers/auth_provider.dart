import 'package:botleji/core/config/server_config.dart';
import 'package:botleji/core/utils/logger.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/user_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../controllers/user_mode_controller.dart';
import '../../../drops/controllers/drops_controller.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../../core/services/network_detection_service.dart';
import '../../controllers/collector_subscription_controller.dart';
import '../../../collector/controllers/collector_application_controller.dart';
import '../../data/models/user_data.dart' as auth_models;

// Manual provider definitions (no code generation needed)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final notificationServiceProvider = ChangeNotifierProvider<NotificationService>((ref) {
  return NotificationService();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserData?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserData?>> {
  final AuthRepository _authRepository;
  final Ref _ref;
  static const String _authKey = 'auth_data';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';
  late SharedPreferences _prefs;

  AuthNotifier(this._authRepository, this._ref) : super(const AsyncValue.loading()) {
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Check if there's a token first (faster check)
      final token = _prefs.getString(_tokenKey);
      final isLoggedIn = _prefs.getBool(_isLoggedInKey) ?? false;
      
      if (token != null && isLoggedIn) {
        await _loadSavedAuth();
      } else {
        // No valid auth data, set to null immediately
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      AppLogger.log('Error initializing AuthNotifier: $e');
      // Set to null on error
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final authData = prefs.getString(_authKey);

      // AppLogger.log('Loading saved auth - Token: $token');
      // AppLogger.log('Loading saved auth - Auth data: $authData');

      if (token != null) {
        try {
          AppLogger.log('🔍 Loading saved auth data...');
          
          // Always call backend to get fresh user data (including lock status)
          AppLogger.log('🔄 Calling backend to get fresh user data...');
          final response = await _authRepository.getProfile();
          AppLogger.log('✅ Backend response received');
          
          final userData = response.when(
            success: (user, token, message) => user,
            error: (message, statusCode) => throw Exception('Failed to get fresh user data: $message'),
          );
          
          if (userData == null) {
            throw Exception('No user data received from backend');
          }
          AppLogger.log('🔒 FRESH LOCK STATUS FROM BACKEND:');
          AppLogger.log('   - isAccountLocked: ${userData.isAccountLocked}');
          AppLogger.log('   - accountLockedUntil: ${userData.accountLockedUntil}');
          AppLogger.log('   - warningCount: ${userData.warningCount}');
          AppLogger.log('   - isCurrentlyLocked: ${userData.isCurrentlyLocked}');
          
          // Update saved auth data with fresh backend data
          await prefs.setString(_authKey, jsonEncode(userData.toJson()));
          AppLogger.log('💾 Updated cached auth data with fresh backend data');
          
          state = AsyncValue.data(userData);
          
          // Set user mode based on roles
          await _setUserModeFromRoles(userData.roles);
          
          // Reconnect to WebSocket notifications on app startup
          AppLogger.log('🔌 AuthProvider: Reconnecting to WebSocket on app startup');
          _connectToNotificationsOnStartup(token);
          
          // Set up application status update callback
          _setupApplicationStatusCallback();
          
          // Sync application status from database
          await syncApplicationStatusFromDatabase();
          
        } catch (e) {
          // AppLogger.log('Error parsing saved auth data: $e');
          await _clearAuth();
          state = const AsyncValue.data(null);
        }
      } else {
        // AppLogger.log('Loading saved auth - Is logged in: false');
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // AppLogger.log('Error loading saved auth: $e');
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _setUserModeFromRoles(List<String> roles) async {
    try {
          AppLogger.log('🔄 AuthProvider: Setting user mode from roles: $roles');
      
      if (roles.isEmpty) {
        AppLogger.log('⚠️ AuthProvider: No roles provided, skipping user mode setup');
        return;
      }
      
      // Wait for UserModeController to be ready
      int attempts = 0;
      while (attempts < 10) { // Max 5 seconds wait
        try {
          final userModeState = _ref.read(userModeControllerProvider);
          if (userModeState.hasValue) {
            AppLogger.log('✅ AuthProvider: UserModeController is ready');
            break;
          }
        } catch (e) {
          AppLogger.log('⚠️ AuthProvider: Error reading userModeControllerProvider: $e');
        }
        AppLogger.log('⏳ AuthProvider: UserModeController not ready yet, waiting... (attempt ${attempts + 1}/10)');
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      try {
        final userModeController = _ref.read(userModeControllerProvider.notifier);
        
        // Get the current saved mode
        final currentMode = await userModeController.getCurrentMode();
        
        AppLogger.log('🔍 AuthProvider: Current saved mode: ${currentMode?.name}');
        AppLogger.log('🔍 AuthProvider: Current mode backend role: ${currentMode?.backendRole}');
        AppLogger.log('🔍 AuthProvider: User roles: $roles');
        AppLogger.log('🔍 AuthProvider: Does user have current mode role? ${currentMode != null ? roles.contains(currentMode.backendRole) : false}');
        
        // Check if the current mode is still valid (user still has that role)
        if (currentMode != null && roles.contains(currentMode.backendRole)) {
          // Keep the current mode if it's still valid
          AppLogger.log('✅ AuthProvider: Keeping current mode: ${currentMode.name} (user still has role: ${currentMode.backendRole})');
          // Don't call setMode again if it's already the correct mode
          try {
            final currentState = _ref.read(userModeControllerProvider);
            if (currentState.hasValue && currentState.value == currentMode) {
              AppLogger.log('✅ AuthProvider: Mode is already set correctly, skipping setMode call');
            } else {
              AppLogger.log('🔄 AuthProvider: Mode needs to be updated, calling setMode');
              await userModeController.setMode(currentMode);
            }
          } catch (e) {
            AppLogger.log('⚠️ AuthProvider: Error checking/updating mode: $e');
            // Fallback: just set the mode
            await userModeController.setMode(currentMode);
          }
        } else {
          // If no saved mode or invalid mode, default to household for users with both roles
          final mode = UserMode.household;
          AppLogger.log('🔄 AuthProvider: Setting default mode: ${mode.name} (from roles: $roles)');
          AppLogger.log('🔄 AuthProvider: Reason: ${currentMode == null ? 'No saved mode' : 'Invalid mode for current roles'}');
          await userModeController.setMode(mode);
        }
        
        AppLogger.log('✅ AuthProvider: User mode set successfully');
      } catch (e, stackTrace) {
        AppLogger.log('❌ AuthProvider: Error in user mode controller operations: $e');
        AppLogger.log('❌ AuthProvider: Stack trace: $stackTrace');
        rethrow;
      }
    } catch (e, stackTrace) {
      AppLogger.log('❌ AuthProvider: Error setting user mode: $e');
      AppLogger.log('❌ AuthProvider: Stack trace: $stackTrace');
      // Don't rethrow - let login continue even if user mode setup fails
    }
  }

  Future<void> _saveAuth(UserData userData) async {
    try {
      AppLogger.log('💾 AuthProvider: Saving user data to shared preferences...');
      AppLogger.log('💾 AuthProvider: User ID: ${userData.id}');
      AppLogger.log('💾 AuthProvider: Application status: ${userData.collectorApplicationStatus}');
      
      final authData = jsonEncode(userData.toJson());
      await _prefs.setString(_authKey, authData);
      await _prefs.setBool(_isLoggedInKey, true);
    await _prefs.setBool('is_first_time', false);
      
      AppLogger.log('💾 AuthProvider: User data saved successfully');
    } catch (e) {
      AppLogger.log('❌ AuthProvider: Error saving user data: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      AppLogger.log('Saving token: $token');
      await _prefs.setString(_tokenKey, token);
    } catch (e) {
      AppLogger.log('Error saving token: $e');
    }
  }

  Future<void> _clearAuth() async {
    try {
      AppLogger.log('=== Before Clearing Auth Data ===');
      AppLogger.log('Token: ${_prefs.getString(_tokenKey)}');
      AppLogger.log('Auth Data: ${_prefs.getString(_authKey)}');
      AppLogger.log('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      AppLogger.log('Clearing auth data and token...');
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_authKey);
      await _prefs.setBool(_isLoggedInKey, false);
      
      AppLogger.log('=== After Clearing Auth Data ===');
      AppLogger.log('Token: ${_prefs.getString(_tokenKey)}');
      AppLogger.log('Auth Data: ${_prefs.getString(_authKey)}');
      AppLogger.log('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      AppLogger.log('Auth data and token cleared successfully');
    } catch (e) {
      AppLogger.log('Error clearing auth data: $e');
    }
  }

  Future<UserData?> login(String email, String password, WidgetRef ref) async {
    try {
      AppLogger.log('Starting login process...');
      
      final response = await _authRepository.login(email: email, password: password);
      AppLogger.log('Login response: $response');
      
      return response.when(
        success: (user, token, message) async {
          AppLogger.log('Login success - User: $user, Token: $token, Message: $message');
          if (user != null && token != null) {
            AppLogger.log('Saving user data and token');
            AppLogger.log('User ID: ${user.id}');
            AppLogger.log('User roles: ${user.roles}');
            AppLogger.log('User isCollector: ${user.isCollector}');
            AppLogger.log('User isHousehold: ${user.isHousehold}');
            AppLogger.log('🔒 LOCK STATUS:');
            AppLogger.log('   - isAccountLocked: ${user.isAccountLocked}');
            AppLogger.log('   - accountLockedUntil: ${user.accountLockedUntil}');
            AppLogger.log('   - warningCount: ${user.warningCount}');
            AppLogger.log('   - isCurrentlyLocked: ${user.isCurrentlyLocked}');
            _saveAuth(user);
            _saveToken(token);
            state = AsyncValue.data(user);
            
            // Set user mode first (await it to ensure it completes)
            try {
              await _setUserModeFromRoles(user.roles);
            } catch (e, stackTrace) {
              AppLogger.log('❌ Error setting user mode: $e');
              AppLogger.log('❌ Stack trace: $stackTrace');
              // Don't fail login if user mode setting fails
            }
            
            // Connect to notifications (non-blocking, but log errors)
            try {
              _connectToNotifications(token, ref);
            } catch (e) {
              AppLogger.log('❌ Error connecting to notifications: $e');
              // Don't fail login if WebSocket connection fails
            }
            
            // Note: Skip syncing application status after login since we already have fresh user data
            // syncApplicationStatusFromDatabase().catchError((e) {
            //   AppLogger.log('Error syncing application status after login: $e');
            // });
            
            return user;
          } else {
            AppLogger.log('Login failed - Missing user or token');
            return null;
          }
        },
        error: (message, statusCode) {
          AppLogger.log('Login error: $message (Status: $statusCode)');
          throw Exception(message);
        },
      );
    } catch (e, stack) {
      AppLogger.log('Login exception: $e');
      // Re-throw the exception so the UI can handle it
      rethrow;
    }
  }

  

  Future<AuthResponse> signup({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.log('AuthNotifier: Starting signup process...');
      AppLogger.log('AuthNotifier: Email: $email');
      
      final response = await _authRepository.signup(
        email: email,
        password: password,
      );
      
      AppLogger.log('AuthNotifier: Signup response: $response');
      
      response.when(
        success: (user, token, message) {
          AppLogger.log('AuthNotifier: Signup successful');
          AppLogger.log('AuthNotifier: Message: $message');
          
          // Create a temporary user object for OTP verification
          if (user == null && (message?.contains('verify your email') ?? false)) {
            AppLogger.log('Creating temporary user for OTP verification');
            final tempUser = UserData(
              id: '',
              email: email,
              name: '',
              phoneNumber: '',
              address: '',
              profilePhoto: '',
              roles: ['household'],
              collectorSubscriptionType: 'basic',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isProfileComplete: false,
            );
            // Save the temporary user data
            _saveAuth(tempUser);
            state = AsyncValue.data(tempUser);
          } else if (user != null) {
            state = AsyncValue.data(user);
          } else {
            state = const AsyncValue.data(null);
          }
        },
        error: (message, statusCode) {
          AppLogger.log('AuthNotifier: Signup failed');
          AppLogger.log('AuthNotifier: Error message: $message');
          AppLogger.log('AuthNotifier: Status code: $statusCode');
          state = AsyncValue.error(message, StackTrace.current);
        },
      );
      return response;
    } catch (e, stack) {
      AppLogger.log('AuthNotifier: Signup exception: $e');
      state = AsyncValue.error(e, stack);
      return AuthResponse.error(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<void> logout(WidgetRef ref) async {
    try {
      AppLogger.log('Starting logout process...');
      
      // Disconnect from WebSocket notifications
      try {
        final notificationService = ref.read(notificationServiceProvider);
        notificationService.disconnect();
        AppLogger.log('Disconnected from WebSocket notifications');
      } catch (e) {
        AppLogger.log('Error disconnecting from notifications: $e');
      }
      
      // Clear local data
      AppLogger.log('Clearing local auth data...');
      try {
        await _prefs.remove(_tokenKey);
        await _prefs.remove(_authKey);
        await _prefs.setBool(_isLoggedInKey, false);
      } catch (e) {
        AppLogger.log('Error clearing local auth data: $e');
      }
      
      // Reset user mode controller
      try {
        final userModeController = ref.read(userModeControllerProvider.notifier);
        await userModeController.clearMode();
        AppLogger.log('Reset user mode controller');
      } catch (e) {
        AppLogger.log('Error resetting user mode controller: $e');
      }
      
      // Reset collector subscription controller
      try {
        final subscriptionController = ref.read(collectorSubscriptionControllerProvider.notifier);
        // Force refresh to reset state
        await subscriptionController.refresh();
        AppLogger.log('Reset collector subscription controller');
      } catch (e) {
        AppLogger.log('Error resetting collector subscription controller: $e');
      }
      
      // Reset collector application controller
      try {
        final applicationController = ref.read(collectorApplicationControllerProvider.notifier);
        // Clear any cached application data
        applicationController.clearApplication();
        AppLogger.log('Reset collector application controller');
      } catch (e) {
        AppLogger.log('Error resetting collector application controller: $e');
      }
      
      // Clear drops data
      try {
        final dropsController = ref.read(dropsControllerProvider.notifier);
        dropsController.clearDrops();
        AppLogger.log('Cleared drops data');
      } catch (e) {
        AppLogger.log('Error clearing drops data: $e');
      }
      
      // Clear notification service
      try {
        final notificationService = ref.read(notificationServiceProvider);
        notificationService.clearNotifications();
        AppLogger.log('Cleared notification service');
      } catch (e) {
        AppLogger.log('Error clearing notification service: $e');
      }
      
      // Set state to null (logged out)
      state = const AsyncValue.data(null);
      AppLogger.log('Logout completed successfully');
    } catch (e) {
      AppLogger.log('Error during logout: $e');
      // Even if there's an error, try to clear auth data
      try {
        await _prefs.remove(_tokenKey);
        await _prefs.remove(_authKey);
        await _prefs.setBool(_isLoggedInKey, false);
      } catch (e2) {
        AppLogger.log('Secondary error clearing local auth data: $e2');
      }
      state = const AsyncValue.data(null);
    }
  }

  Future<void> refreshUserData() async {
    try {
      AppLogger.log('🔄 AuthProvider: Refreshing user data from server...');
      
      final response = await _authRepository.refreshUserData();
      
      response.when(
        success: (user, token, message) {
          AppLogger.log('✅ AuthProvider: User data refreshed successfully');
          AppLogger.log('🔄 AuthProvider: New user roles: ${user?.roles}');
          
          if (user != null) {
            // Update the state with new user data
            state = AsyncValue.data(user);
            
            // Save the updated user data
            _saveAuth(user);
            
            // Update user mode based on new roles
            _setUserModeFromRoles(user.roles);
            
            AppLogger.log('✅ AuthProvider: User data and mode updated successfully');
          }
        },
        error: (message, statusCode) {
          AppLogger.log('❌ AuthProvider: Failed to refresh user data: $message (Status: $statusCode)');
          if (statusCode == 401) {
            // Token expired, logout the user
            AppLogger.log('🔐 AuthProvider: Token expired, logging out user');
            // Note: We can't call logout here as it requires a WidgetRef
            // The user will need to manually logout or restart the app
          }
        },
      );
    } catch (e) {
      AppLogger.log('❌ AuthProvider: Error refreshing user data: $e');
    }
  }

  // WebSocket notification methods
  void _connectToNotifications(String token, WidgetRef ref) async {
    try {
      AppLogger.log('🔌 AuthProvider: Setting up WebSocket connection...');
      
      // If using tunnel, skip local network check (tunnel uses public HTTPS/WSS, not local network)
      // Only check local network permission if NOT using tunnel
      if (!ServerConfig.isUsingTunnel) {
        final prefs = await SharedPreferences.getInstance();
        final localNetworkGranted = prefs.getBool('local_network_granted') ?? false;
        if (!localNetworkGranted) {
          AppLogger.log('🔌 AuthProvider: Skipping WebSocket connect (local network not granted yet and not using tunnel)');
          return;
        }
      } else {
        AppLogger.log('🔌 AuthProvider: Using tunnel, skipping local network permission check');
      }
      
      // Skip network detection if auto-detection is disabled (use fallback directly)
      if (ServerConfig.useAutoDetection) {
        AppLogger.log('🔌 AuthProvider: Waiting for network detection...');
        await NetworkDetectionService.getOptimalServerIp();
        AppLogger.log('🔌 AuthProvider: Network detection completed');
      } else {
        AppLogger.log('🔌 AuthProvider: Auto-detection disabled, using configured IP');
      }
      
      final notificationService = ref.read(notificationServiceProvider);
      
      // Set up force logout callback
      notificationService.onForceLogout = (reason) {
        AppLogger.log('🚪 Force logout received: $reason');
        // Show a dialog and then logout
        handleForceLogout(reason);
      };
      
      // Set up drop status update callback for real-time updates
      notificationService.onDropStatusUpdate = (dropId, status, data) {
        AppLogger.log('🔄 AuthProvider: Drop status update received - $status for drop $dropId');
        // Update drops controller with the status change
        final dropsController = ref.read(dropsControllerProvider.notifier);
        dropsController.handleDropStatusUpdate(dropId, status, data);
      };
      
      // Connect to WebSocket
      AppLogger.log('🔌 AuthProvider: Calling notificationService.connect()...');
      notificationService.connect(token);
      AppLogger.log('🔌 AuthProvider: WebSocket connection initiated');
      
      // Check connection status after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        final isConnected = notificationService.isConnected;
        AppLogger.log('🔌 AuthProvider: WebSocket connection status after 2s: $isConnected');
      });
      
    } catch (e) {
      AppLogger.log('❌ AuthProvider: Error connecting to notifications: $e');
    }
  }

  /// Connect to WebSocket on app startup (without WidgetRef)
  void _connectToNotificationsOnStartup(String token) async {
    try {
      AppLogger.log('🔌 AuthProvider: Setting up WebSocket connection on startup...');
      AppLogger.log('🔌 AuthProvider: Token length: ${token.length}');
      
      // If using tunnel, skip local network check (tunnel uses public HTTPS/WSS, not local network)
      // Only check local network permission if NOT using tunnel
      if (!ServerConfig.isUsingTunnel) {
        final prefs = await SharedPreferences.getInstance();
        final localNetworkGranted = prefs.getBool('local_network_granted') ?? false;
        if (!localNetworkGranted) {
          AppLogger.log('🔌 AuthProvider: Skipping WebSocket connect on startup (local network not granted yet and not using tunnel)');
          return;
        }
      } else {
        AppLogger.log('🔌 AuthProvider: Using tunnel on startup, skipping local network permission check');
      }
      
      // Skip network detection if auto-detection is disabled (use fallback directly)
      if (ServerConfig.useAutoDetection) {
        AppLogger.log('🔌 AuthProvider: Waiting for network detection...');
        await NetworkDetectionService.getOptimalServerIp();
        AppLogger.log('🔌 AuthProvider: Network detection completed');
      } else {
        AppLogger.log('🔌 AuthProvider: Auto-detection disabled, using configured IP');
      }
      
      final notificationService = _ref.read(notificationServiceProvider);
      
      // Set up force logout callback
      notificationService.onForceLogout = (reason) {
        AppLogger.log('🚪 Force logout received on startup: $reason');
        AppLogger.log('🚪 AuthProvider: About to call handleForceLogout');
        // Show a dialog and then logout
        handleForceLogout(reason);
        AppLogger.log('🚪 AuthProvider: handleForceLogout completed');
      };
      
      // Set up drop status update callback for real-time updates
      notificationService.onDropStatusUpdate = (dropId, status, data) {
        AppLogger.log('🔄 AuthProvider: Drop status update received on startup - $status for drop $dropId');
        // Update drops controller with the status change
        final dropsController = _ref.read(dropsControllerProvider.notifier);
        dropsController.handleDropStatusUpdate(dropId, status, data);
      };
      
      // Set up account lock status update callback
      notificationService.onAccountLockStatusUpdate = (isLocked, lockedUntil, warningCount) {
        AppLogger.log('🔒 AuthProvider: Account lock status update received!');
        AppLogger.log('   - isLocked: $isLocked');
        AppLogger.log('   - lockedUntil: $lockedUntil');
        AppLogger.log('   - warningCount: $warningCount');
        
        // Update user state immediately
        final currentUser = state.value;
        if (currentUser != null) {
          final updatedUser = UserData(
            id: currentUser.id,
            name: currentUser.name,
            email: currentUser.email,
            phoneNumber: currentUser.phoneNumber,
            address: currentUser.address,
            roles: currentUser.roles,
            profilePhoto: currentUser.profilePhoto,
            collectorSubscriptionType: currentUser.collectorSubscriptionType,
            createdAt: currentUser.createdAt,
            updatedAt: currentUser.updatedAt,
            isProfileComplete: currentUser.isProfileComplete,
            isPhoneVerified: currentUser.isPhoneVerified,
            isAccountLocked: isLocked,
            accountLockedUntil: lockedUntil,
            warningCount: warningCount,
          );
          
          state = AsyncValue.data(updatedUser);
          
          // Update cached data
          SharedPreferences.getInstance().then((prefs) {
            prefs.setString(_authKey, jsonEncode(updatedUser.toJson()));
            AppLogger.log('💾 AuthProvider: Updated cached user data with new lock status');
          });
          
          AppLogger.log('✅ AuthProvider: User state updated with new lock status');
        }
      };
      
      // Connect to WebSocket
      AppLogger.log('🔌 AuthProvider: Calling notificationService.connect() on startup...');
      notificationService.connect(token);
      AppLogger.log('🔌 AuthProvider: WebSocket connection initiated on startup');
      
      // Check connection status after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        final isConnected = notificationService.isConnected;
        AppLogger.log('🔌 AuthProvider: WebSocket connection status after 2s: $isConnected');
        if (!isConnected) {
          AppLogger.log('❌ AuthProvider: WebSocket failed to connect on startup');
        }
      });
      
    } catch (e) {
      AppLogger.log('❌ AuthProvider: Error connecting to notifications on startup: $e');
    }
  }

  void _disconnectFromNotifications(WidgetRef ref) {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.disconnect();
      AppLogger.log('🔌 Disconnected from WebSocket notifications');
    } catch (e) {
      AppLogger.log('❌ Error disconnecting from notifications: $e');
    }
  }

  void handleForceLogout(String reason) {
    AppLogger.log('🚪 Handling force logout: $reason');
    AppLogger.log('🚪 AuthProvider: handleForceLogout called with reason: $reason');
    
    // Show force logout notification immediately
    try {
      LocalNotificationService().showForceLogoutNotification(reason: reason);
      AppLogger.log('🔔 Force logout notification sent');
    } catch (e) {
      AppLogger.log('❌ Error showing force logout notification: $e');
    }
    
    // Store the force logout reason to show dialog
    _pendingForceLogoutReason = reason;
    AppLogger.log('🚪 Force logout reason stored: $reason');
    AppLogger.log('🚪 AuthProvider: _pendingForceLogoutReason set to: $_pendingForceLogoutReason');
    
    // Trigger a state change to make the auth listener run
    // We'll set a temporary flag in the state to trigger the listener
    final currentUser = state.value;
    if (currentUser != null) {
      // Create a temporary user with a flag to trigger state change
      final tempUser = UserData(
        id: currentUser.id,
        email: currentUser.email,
        name: currentUser.name,
        phoneNumber: currentUser.phoneNumber,
        address: currentUser.address,
        profilePhoto: currentUser.profilePhoto,
        roles: currentUser.roles,
        collectorSubscriptionType: currentUser.collectorSubscriptionType,
        createdAt: currentUser.createdAt,
        updatedAt: currentUser.updatedAt,
        isProfileComplete: currentUser.isProfileComplete,
        isDeleted: currentUser.isDeleted,
        deletedAt: currentUser.deletedAt,
        deletedBy: currentUser.deletedBy,
        sessionInvalidatedAt: currentUser.sessionInvalidatedAt,
      );
      
      // Set state to trigger the listener
      state = AsyncValue.data(tempUser);
      AppLogger.log('🚪 AuthProvider: State updated to trigger auth listener');
    }
    
    // Don't clear auth data immediately - let user see the warning first
    AppLogger.log('🚪 Force logout initiated - waiting for user acknowledgment');
  }

  /// Get pending force logout reason and clear it
  String? getPendingForceLogoutReason() {
    final reason = _pendingForceLogoutReason;
    _pendingForceLogoutReason = null;
    return reason;
  }

  /// Execute the actual force logout after user acknowledges
  void executeForceLogout() {
    AppLogger.log('🚪 Executing force logout after user acknowledgment');
    
    // Clear all data immediately and set state to null
    _clearAuthAndSetState();
    
    AppLogger.log('🚪 Force logout completed successfully');
  }

  String? _pendingForceLogoutReason;

  /// Clear auth data and set state to null immediately
  void _clearAuthAndSetState() async {
    // Set state to null immediately first
    state = const AsyncValue.data(null);
    AppLogger.log('✅ Auth state set to null immediately');
    
    try {
      AppLogger.log('=== Before Clearing Auth Data ===');
      AppLogger.log('Token: ${_prefs.getString(_tokenKey)}');
      AppLogger.log('Auth Data: ${_prefs.getString(_authKey)}');
      AppLogger.log('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      AppLogger.log('Clearing auth data and token...');
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_authKey);
      await _prefs.setBool(_isLoggedInKey, false);
      
      AppLogger.log('=== After Clearing Auth Data ===');
      AppLogger.log('Token: ${_prefs.getString(_tokenKey)}');
      AppLogger.log('Auth Data: ${_prefs.getString(_authKey)}');
      AppLogger.log('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      AppLogger.log('Auth data and token cleared successfully');
      
    } catch (e) {
      AppLogger.log('Error clearing auth data: $e');
      // State is already set to null, so no need to set it again
    }
  }

  Future<void> setupProfile({
  String? name,
  String? phone,
  String? address,
  String? profilePhoto,
}) async {
  try {
    final currentUser = state.value;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    AppLogger.log('setupProfile: Sending data:');
    AppLogger.log('  name: $name');
    AppLogger.log('  phone: $phone');
    AppLogger.log('  address: $address');
    AppLogger.log('  profilePhoto: $profilePhoto');

    final response = await _authRepository.setupProfile(
      name: name,
      phoneNumber: phone,
      address: address,
      profilePhoto: profilePhoto,
    );

    AppLogger.log('setupProfile: Response: $response');

    response.when(
      success: (user, token, message) async {
        // Merge fields with priority: server user > form values > current user
        final updatedUser = UserData(
          id:               user?.id               ?? currentUser.id,
          email:            user?.email            ?? currentUser.email,
          name:             user?.name             ?? name         ?? currentUser.name,
          phoneNumber:      user?.phoneNumber      ?? phone        ?? currentUser.phoneNumber,
          address:          user?.address          ?? address      ?? currentUser.address,
          profilePhoto:     user?.profilePhoto     ?? profilePhoto ?? currentUser.profilePhoto,
          roles:            user?.roles            ?? currentUser.roles,
          collectorSubscriptionType:
                             user?.collectorSubscriptionType ?? currentUser.collectorSubscriptionType,
          createdAt:        user?.createdAt        ?? currentUser.createdAt,
          updatedAt:        user?.updatedAt        ?? DateTime.now(),
          // After profile setup, we consider it complete unless server says otherwise
          isProfileComplete: user?.isProfileComplete ?? true,
        );

        AppLogger.log('setupProfile: Updated user id=${updatedUser.id}');
        AppLogger.log('setupProfile: name=${updatedUser.name}, phone=${updatedUser.phoneNumber}');
        AppLogger.log('setupProfile: address=${updatedUser.address}, photo=${updatedUser.profilePhoto}');
        AppLogger.log('setupProfile: isProfileComplete=${updatedUser.isProfileComplete}');

        state = AsyncValue.data(updatedUser);
        await _saveAuth(updatedUser);

        if (token != null && token.isNotEmpty) {
          AppLogger.log('setupProfile: Saving new token after profile setup');
          await _saveToken(token);
        }

        AppLogger.log('setupProfile: State and storage updated');
      },
      error: (message, _) {
        AppLogger.log('setupProfile: Error from backend: $message');
        state = AsyncValue.error(message, StackTrace.current);
        throw Exception(message);
      },
    );
  } catch (e, stack) {
    AppLogger.log('setupProfile: Exception: $e');
    state = AsyncValue.error(e, stack);
    rethrow;
  }
}


  Future<void> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? profilePhoto,
  }) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) throw Exception('No user logged in');

      AppLogger.log('updateProfile: Sending data:');
      AppLogger.log('  name: $name');
      AppLogger.log('  phone: $phone');
      AppLogger.log('  address: $address');
      AppLogger.log('  profilePhoto: $profilePhoto');

      final response = await _authRepository.updateProfile(
        name: name,
        phoneNumber: phone,
        address: address,
        profilePhoto: profilePhoto,
      );
      AppLogger.log('updateProfile: Response: $response');

      response.when(
        success: (user, token, message) {
          if (user != null) {
            final updatedUser = UserData(
              id: user.id,
              email: user.email,
              name: user.name ?? name ?? currentUser.name,
              phoneNumber: phone ?? currentUser.phoneNumber,
              address: user.address ?? address ?? currentUser.address,
              profilePhoto: user.profilePhoto ?? profilePhoto ?? currentUser.profilePhoto,
              roles: user.roles ?? currentUser.roles,
              collectorSubscriptionType: user.collectorSubscriptionType ?? currentUser.collectorSubscriptionType,
              createdAt: user.createdAt ?? currentUser.createdAt,
              updatedAt: user.updatedAt ?? currentUser.updatedAt,
              isProfileComplete: user.isProfileComplete ?? currentUser.isProfileComplete,
            );
            AppLogger.log('updateProfile: Updated user with ID: ${updatedUser.id}');
            AppLogger.log('updateProfile: Updated user phone: ${updatedUser.phoneNumber}');
            AppLogger.log('updateProfile: Updated user name: ${updatedUser.name}');
            AppLogger.log('updateProfile: Updated user address: ${updatedUser.address}');
            AppLogger.log('updateProfile: Updated user profilePhoto: ${updatedUser.profilePhoto}');
            state = AsyncValue.data(updatedUser);
            _saveAuth(updatedUser);
            
            // Save new token if provided
            if (token != null) {
              AppLogger.log('updateProfile: Saving new token after profile update');
              _saveToken(token);
            }
            
            AppLogger.log('updateProfile: State and SharedPreferences updated.');
          } else {
            AppLogger.log('updateProfile: Success but user is null!');
            throw Exception('Profile update succeeded but user is null');
          }
        },
        error: (message, _) {
          AppLogger.log('updateProfile: Error from backend: $message');
          state = AsyncValue.error(message, StackTrace.current);
          throw Exception(message);
        },
      );
    } catch (e, stack) {
      AppLogger.log('updateProfile: Exception: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
  

  Future<AuthResponse> verifyOtp(String email, String otp) async {
    try {
      AppLogger.log('Verifying OTP for email: $email');
      final response = await _authRepository.verifyOtp(email: email, otp: otp);
      AppLogger.log('OTP verification response: $response');
      
      response.when(
        success: (user, token, message) {
          AppLogger.log('OTP verification success - User: $user, Token: $token');
          if (token != null && user != null) {
            AppLogger.log('Saving user data and token after OTP verification');
            AppLogger.log('User ID from backend: ${user.id}');
            _saveAuth(user);
            _saveToken(token);
            _setUserModeFromRoles(user.roles);
            state = AsyncValue.data(user);
          } else if (token != null && user == null) {
            AppLogger.log('Creating new user object with token (fallback)');
            final newUser = UserData(
              id: '',
              email: email,
              name: '',
              phoneNumber: '',
              address: '',
              profilePhoto: '',
              roles: ['household'],
              collectorSubscriptionType: 'basic',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isProfileComplete: false,
            );
            AppLogger.log('Saving user data and token after OTP verification');
            _saveAuth(newUser);
            _saveToken(token);
            _setUserModeFromRoles(newUser.roles);
            state = AsyncValue.data(newUser);
          } else {
            AppLogger.log('Warning: No token received after OTP verification');
            state = AsyncValue.error('Invalid verification response', StackTrace.current);
          }
        },
        error: (message, statusCode) {
          AppLogger.log('OTP verification error: $message (Status: $statusCode)');
          state = AsyncValue.error(message, StackTrace.current);
        },
      );
      return response;
    } catch (e, stackTrace) {
      AppLogger.log('Error in verifyOtp: $e');
      state = AsyncValue.error(e, stackTrace);
      return AuthResponse.error(message: 'Failed to verify OTP: ${e.toString()}');
    }
  }
  

  Future<void> resendOtp(String email) async {
    await _authRepository.resendOtp(email);
  }

  Future<AuthResponse> requestPasswordReset(String email) async {
    try {
      final response = await _authRepository.requestPasswordReset(email);
      return response;
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  Future<AuthResponse> verifyPasswordReset({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _authRepository.verifyPasswordReset(
        email: email,
        otp: otp,
      );
      return response;
    } catch (e, stackTrace) {
      rethrow;
    }
  }

  Future<AuthResponse> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _authRepository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return response;
    } catch (e, stackTrace) {
      rethrow;
    }
  }



  Future<void> handleSessionExpiration(BuildContext context) async {
    try {
      AppLogger.log('Handling session expiration...');
      
      // Clear all cached data
      await _clearAuth();
      
      // Clear user mode
      final userModeController = _ref.read(userModeControllerProvider.notifier);
      await userModeController.clearMode();
      
      // Update state
      state = const AsyncValue.data(null);
      
      // Show session expired dialog
      if (context.mounted) {
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
                    // Navigate to login screen
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
      AppLogger.log('Session expiration handled successfully');
    } catch (e) {
      AppLogger.log('Error handling session expiration: $e');
    }
  }

  Future<void> checkSessionExpiration() async {
    try {
      final token = _prefs.getString(_tokenKey);
      if (token == null) return;

      // Try to get profile to check if token is still valid
      final response = await _authRepository.getProfile();
      
      response.when(
        success: (user, token, message) {
          AppLogger.log('Session is still valid');
        },
        error: (message, statusCode) async {
          if (statusCode == 401) {
            AppLogger.log('Session expired detected');
            await _handleSessionExpiration();
          }
        },
      );
    } catch (e) {
      AppLogger.log('Error checking session expiration: $e');
    }
  }

  Future<void> _handleSessionExpiration() async {
    try {
      AppLogger.log('Handling session expiration...');
      
      // Clear all cached data
      await _clearAuth();
      
      // Clear user mode
      final userModeController = _ref.read(userModeControllerProvider.notifier);
      await userModeController.clearMode();
      
      // Update state
      state = const AsyncValue.data(null);
      
      AppLogger.log('Session expiration handled successfully');
    } catch (e) {
      AppLogger.log('Error handling session expiration: $e');
    }
  }

  Future<AuthResponse> checkSessionValidity() async {
    try {
      final currentUser = state.value;
      if (currentUser == null) {
        return AuthResponse.error(message: 'No user logged in', statusCode: 401);
      }

      AppLogger.log('Checking session validity...');
      
      // Get fresh user data from backend
      final response = await _authRepository.getProfile();
      
      return response;
    } catch (e) {
      AppLogger.log('Error checking session validity: $e');
      return AuthResponse.error(message: 'Session check failed: $e', statusCode: 500);
    }
  }

  Future<void> handleGlobal401Error(BuildContext context) async {
    try {
      AppLogger.log('Handling global 401 error...');
      
      // Clear all cached data
      await _clearAuth();
      
      // Clear user mode
      final userModeController = _ref.read(userModeControllerProvider.notifier);
      await userModeController.clearMode();
      
      // Update state
      state = const AsyncValue.data(null);
      
      // Show session expired dialog
      if (context.mounted) {
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
                    // Navigate to login screen
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
      AppLogger.log('Global 401 error handled successfully');
    } catch (e) {
      AppLogger.log('Error handling global 401 error: $e');
    }
  }

  // Handle collector application status updates
  void updateCollectorApplicationStatus({
    required auth_models.CollectorApplicationStatus status,
    String? applicationId,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    AppLogger.log('🔄 AuthProvider: Updating collector application status to: $status');
    
    // Get current user data directly from state
    final currentState = state;
    if (!currentState.hasValue || currentState.value == null) {
      AppLogger.log('⚠️ AuthProvider: Cannot update application status - no user data in state');
      return;
    }
    
    final userData = currentState.value!;
    
    // Ensure we don't duplicate 'collector' role if it already exists
    final currentRoles = userData.roles;
    final updatedRoles = status == auth_models.CollectorApplicationStatus.approved 
        ? (currentRoles.contains('collector') ? currentRoles : [...currentRoles, 'collector'])
        : currentRoles;
    
    final updatedUserData = UserData(
      id: userData.id,
      email: userData.email,
      name: userData.name,
      phoneNumber: userData.phoneNumber,
      address: userData.address,
      profilePhoto: userData.profilePhoto,
      roles: updatedRoles,
      collectorSubscriptionType: userData.collectorSubscriptionType,
      createdAt: userData.createdAt,
      updatedAt: userData.updatedAt,
      isProfileComplete: userData.isProfileComplete,
      isDeleted: userData.isDeleted,
      deletedAt: userData.deletedAt,
      deletedBy: userData.deletedBy,
      sessionInvalidatedAt: userData.sessionInvalidatedAt,
      isAccountLocked: userData.isAccountLocked,
      accountLockedUntil: userData.accountLockedUntil,
      warningCount: userData.warningCount,
      collectorApplicationStatus: status,
      collectorApplicationId: applicationId,
      collectorApplicationAppliedAt: appliedAt,
      collectorApplicationReviewedAt: reviewedAt,
      collectorApplicationRejectionReason: rejectionReason,
    );
    
    // Update state - this should trigger a rebuild of widgets watching this provider
    state = AsyncValue.data(updatedUserData);
    
    // Save to shared preferences
    _saveAuth(updatedUserData);
    
    // If application is approved and user now has collector role, update user mode
    if (status == auth_models.CollectorApplicationStatus.approved && updatedRoles.contains('collector')) {
      _setUserModeFromRoles(updatedRoles);
    }
    
    AppLogger.log('🔄 AuthProvider: Application status updated successfully');
    AppLogger.log('🔄 AuthProvider: Updated roles: $updatedRoles');
    AppLogger.log('🔄 AuthProvider: Updated application status: $status');
  }

  // Clear application status (when user applies again after rejection)
  void clearCollectorApplicationStatus() {
    AppLogger.log('🔄 AuthProvider: Clearing collector application status');
    
    state.whenData((userData) {
      if (userData != null) {
        final updatedUserData = UserData(
          id: userData.id,
          email: userData.email,
          name: userData.name,
          phoneNumber: userData.phoneNumber,
          address: userData.address,
          profilePhoto: userData.profilePhoto,
          roles: userData.roles,
          collectorSubscriptionType: userData.collectorSubscriptionType,
          createdAt: userData.createdAt,
          updatedAt: userData.updatedAt,
          isProfileComplete: userData.isProfileComplete,
          isDeleted: userData.isDeleted,
          deletedAt: userData.deletedAt,
          deletedBy: userData.deletedBy,
          sessionInvalidatedAt: userData.sessionInvalidatedAt,
          isAccountLocked: userData.isAccountLocked,
          accountLockedUntil: userData.accountLockedUntil,
          warningCount: userData.warningCount,
          collectorApplicationStatus: null,
          collectorApplicationId: null,
          collectorApplicationAppliedAt: null,
          collectorApplicationReviewedAt: null,
          collectorApplicationRejectionReason: null,
        );
        // Update state
        state = AsyncValue.data(updatedUserData);
        
        // Save to shared preferences
        _saveAuth(updatedUserData);
        
        AppLogger.log('🔄 AuthProvider: Application status cleared successfully');
      }
    });
  }

  // Set up application status update callback
  void _setupApplicationStatusCallback() {
    final notificationService = _ref.read(notificationServiceProvider);
    notificationService.onApplicationStatusUpdate = (status, data) {
      AppLogger.log('🔄 AuthProvider: Application status update received: $status');
      
      switch (status) {
        case 'approved':
          updateCollectorApplicationStatus(
            status: auth_models.CollectorApplicationStatus.approved,
            applicationId: data['applicationId'],
            appliedAt: data['appliedAt'] != null ? DateTime.parse(data['appliedAt']) : null,
            reviewedAt: data['reviewedAt'] != null ? DateTime.parse(data['reviewedAt']) : null,
          );
          // Refresh user data to get updated roles
          refreshUserData();
          break;
        case 'rejected':
          updateCollectorApplicationStatus(
            status: auth_models.CollectorApplicationStatus.rejected,
            applicationId: data['applicationId'],
            appliedAt: data['appliedAt'] != null ? DateTime.parse(data['appliedAt']) : null,
            reviewedAt: data['reviewedAt'] != null ? DateTime.parse(data['reviewedAt']) : null,
            rejectionReason: data['reason'],
          );
          // Refresh user data to get updated roles
          refreshUserData();
          break;
        case 'pending':
          updateCollectorApplicationStatus(
            status: auth_models.CollectorApplicationStatus.pending,
            applicationId: data['applicationId'],
            appliedAt: data['appliedAt'] != null ? DateTime.parse(data['appliedAt']) : null,
            reviewedAt: data['reviewedAt'] != null ? DateTime.parse(data['reviewedAt']) : null,
          );
          // Refresh user data to get updated roles (application was reversed)
          refreshUserData();
          break;
      }
    };
  }

  // Sync application status from database
  Future<void> syncApplicationStatusFromDatabase() async {
    AppLogger.log('🔄 AuthProvider: Syncing application status from database...');
    
    try {
      // Get the current user ID
      final currentUser = state.value;
      if (currentUser == null) {
        AppLogger.log('🔄 AuthProvider: No current user, skipping sync');
        return;
      }

      // Check if user already has application status in shared preferences
      final existingStatus = currentUser.collectorApplicationStatus;
      final existingApplicationId = currentUser.collectorApplicationId;
      AppLogger.log('🔄 AuthProvider: Current application status in shared preferences: $existingStatus');
      AppLogger.log('🔄 AuthProvider: Current application ID in shared preferences: $existingApplicationId');

      // Always sync from database to ensure we have the latest status
      AppLogger.log('🔄 AuthProvider: Fetching latest application status from database...');
        
        // Fetch application status from database
        final collectorApplicationController = _ref.read(collectorApplicationControllerProvider.notifier);
        await collectorApplicationController.getMyApplication();
        
        final applicationAsync = _ref.read(collectorApplicationControllerProvider);
        final application = applicationAsync.value;
        
        if (application != null) {
          AppLogger.log('🔄 AuthProvider: Found application in database: ${application.status}');
          
          // Update shared preferences with the application status
          updateCollectorApplicationStatus(
            status: auth_models.CollectorApplicationStatus.values.firstWhere(
              (e) => e.name == application.status,
              orElse: () => auth_models.CollectorApplicationStatus.pending,
            ),
            applicationId: application.id,
            appliedAt: application.appliedAt,
            reviewedAt: application.reviewedAt,
            rejectionReason: application.rejectionReason,
          );
          
          AppLogger.log('🔄 AuthProvider: Application status synced successfully');
        } else {
          AppLogger.log('🔄 AuthProvider: No application found in database, clearing existing status');
          // Clear existing status if no application found in database
          await _clearCollectorApplicationStatus();
        }
    } catch (e) {
      AppLogger.log('🔄 AuthProvider: Error syncing application status: $e');
    }
  }

  // Clear collector application status from shared preferences
  Future<void> _clearCollectorApplicationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('collectorApplicationStatus');
      await prefs.remove('collectorApplicationId');
      await prefs.remove('collectorApplicationAppliedAt');
      await prefs.remove('collectorApplicationReviewedAt');
      await prefs.remove('collectorApplicationRejectionReason');
      AppLogger.log('🔄 AuthProvider: Cleared collector application status from shared preferences');
    } catch (e) {
      AppLogger.log('🔄 AuthProvider: Error clearing collector application status: $e');
    }
  }
  }
  