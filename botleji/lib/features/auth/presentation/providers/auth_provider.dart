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
      print('Error initializing AuthNotifier: $e');
      // Set to null on error
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _loadSavedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final authData = prefs.getString(_authKey);

      // print('Loading saved auth - Token: $token');
      // print('Loading saved auth - Auth data: $authData');

      if (token != null && authData != null) {
        try {
          final userData = UserData.fromJson(jsonDecode(authData));
          // print('Decoded user data: ${jsonDecode(authData)}');
          // print('Subscription type from JSON: ${userData.collectorSubscriptionType}');
          // print('Loaded user data: $userData');
          // print('Loaded user ID: ${userData.id}');
          // print('Loaded user roles: ${userData.roles}');
          // print('Loaded user phone: ${userData.phone}');
          // print('Loaded user isCollector: ${userData.isCollector}');
          // print('Loaded user isHousehold: ${userData.isHousehold}');
          
          // print('Loading saved auth - Is logged in: true');
          state = AsyncValue.data(userData);
          
          // Set user mode based on roles
          await _setUserModeFromRoles(userData.roles);
          
          // Reconnect to WebSocket notifications on app startup
          print('🔌 AuthProvider: Reconnecting to WebSocket on app startup');
          _connectToNotificationsOnStartup(token);
          
          // Set up application status update callback
          _setupApplicationStatusCallback();
          
          // Sync application status from database
          await syncApplicationStatusFromDatabase();
          
        } catch (e) {
          // print('Error parsing saved auth data: $e');
          await _clearAuth();
          state = const AsyncValue.data(null);
        }
      } else {
        // print('Loading saved auth - Is logged in: false');
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // print('Error loading saved auth: $e');
      state = const AsyncValue.data(null);
    }
  }

  Future<void> _setUserModeFromRoles(List<String> roles) async {
    try {
      print('🔄 AuthProvider: Setting user mode from roles: $roles');
      final userModeController = _ref.read(userModeControllerProvider.notifier);
      
      // Get the current saved mode
      final currentMode = await userModeController.getCurrentMode();
      print('🔍 AuthProvider: Current saved mode: ${currentMode?.name}');
      
      // Check if the current mode is still valid (user still has that role)
      if (currentMode != null && roles.contains(currentMode.backendRole)) {
        // Keep the current mode if it's still valid
        print('✅ AuthProvider: Keeping current mode: ${currentMode.name} (user still has role: ${currentMode.backendRole})');
        await userModeController.setMode(currentMode);
      } else {
        // If no saved mode or invalid mode, default to household for users with both roles
        final mode = UserMode.household;
        print('🔄 AuthProvider: Setting default mode: ${mode.name} (from roles: $roles)');
        await userModeController.setMode(mode);
      }
      
      print('✅ AuthProvider: User mode set to: ${currentMode?.name ?? 'default'} (from roles: $roles)');
    } catch (e) {
      print('❌ AuthProvider: Error setting user mode: $e');
    }
  }

  Future<void> _saveAuth(UserData userData) async {
    try {
      print('💾 AuthProvider: Saving user data to shared preferences...');
      print('💾 AuthProvider: User ID: ${userData.id}');
      print('💾 AuthProvider: Application status: ${userData.collectorApplicationStatus}');
      
      final authData = jsonEncode(userData.toJson());
      await _prefs.setString(_authKey, authData);
      await _prefs.setBool(_isLoggedInKey, true);
      
      print('💾 AuthProvider: User data saved successfully');
    } catch (e) {
      print('❌ AuthProvider: Error saving user data: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      print('Saving token: $token');
      await _prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  Future<void> _clearAuth() async {
    try {
      print('=== Before Clearing Auth Data ===');
      print('Token: ${_prefs.getString(_tokenKey)}');
      print('Auth Data: ${_prefs.getString(_authKey)}');
      print('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      print('Clearing auth data and token...');
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_authKey);
      await _prefs.setBool(_isLoggedInKey, false);
      
      print('=== After Clearing Auth Data ===');
      print('Token: ${_prefs.getString(_tokenKey)}');
      print('Auth Data: ${_prefs.getString(_authKey)}');
      print('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      print('Auth data and token cleared successfully');
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  Future<UserData?> login(String email, String password, WidgetRef ref) async {
    try {
      print('Starting login process...');
      
      final response = await _authRepository.login(email: email, password: password);
      print('Login response: $response');
      
      return response.when(
        success: (user, token, message) {
          print('Login success - User: $user, Token: $token, Message: $message');
          if (user != null && token != null) {
            print('Saving user data and token');
            print('User ID: ${user.id}');
            print('User roles: ${user.roles}');
            print('User isCollector: ${user.isCollector}');
            print('User isHousehold: ${user.isHousehold}');
            _saveAuth(user);
            _saveToken(token);
            state = AsyncValue.data(user);
            _connectToNotifications(token, ref);
            try {
              _setUserModeFromRoles(user.roles);
            } catch (e) {
              print('Error setting user mode: $e');
            }
            
            // Sync application status from database after login
            syncApplicationStatusFromDatabase().catchError((e) {
              print('Error syncing application status after login: $e');
            });
            
            return user;
          } else {
            print('Login failed - Missing user or token');
            return null;
          }
        },
        error: (message, statusCode) {
          print('Login error: $message (Status: $statusCode)');
          throw Exception(message);
        },
      );
    } catch (e, stack) {
      print('Login exception: $e');
      // Re-throw the exception so the UI can handle it
      rethrow;
    }
  }

  

  Future<AuthResponse> signup({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthNotifier: Starting signup process...');
      print('AuthNotifier: Email: $email');
      
      final response = await _authRepository.signup(
        email: email,
        password: password,
      );
      
      print('AuthNotifier: Signup response: $response');
      
      response.when(
        success: (user, token, message) {
          print('AuthNotifier: Signup successful');
          print('AuthNotifier: Message: $message');
          
          // Create a temporary user object for OTP verification
          if (user == null && (message?.contains('verify your email') ?? false)) {
            print('Creating temporary user for OTP verification');
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
          print('AuthNotifier: Signup failed');
          print('AuthNotifier: Error message: $message');
          print('AuthNotifier: Status code: $statusCode');
          state = AsyncValue.error(message, StackTrace.current);
        },
      );
      return response;
    } catch (e, stack) {
      print('AuthNotifier: Signup exception: $e');
      state = AsyncValue.error(e, stack);
      return AuthResponse.error(
        message: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<void> logout(WidgetRef ref) async {
    try {
      print('Starting logout process...');
      
      // Disconnect from WebSocket notifications
      try {
        final notificationService = ref.read(notificationServiceProvider);
        notificationService.disconnect();
        print('Disconnected from WebSocket notifications');
      } catch (e) {
        print('Error disconnecting from notifications: $e');
      }
      
      // Clear local data
      print('Clearing local auth data...');
      try {
        await _prefs.remove(_tokenKey);
        await _prefs.remove(_authKey);
        await _prefs.setBool(_isLoggedInKey, false);
      } catch (e) {
        print('Error clearing local auth data: $e');
      }
      
      // Reset user mode controller
      try {
        final userModeController = ref.read(userModeControllerProvider.notifier);
        await userModeController.clearMode();
        print('Reset user mode controller');
      } catch (e) {
        print('Error resetting user mode controller: $e');
      }
      
      // Reset collector subscription controller
      try {
        final subscriptionController = ref.read(collectorSubscriptionControllerProvider.notifier);
        // Force refresh to reset state
        await subscriptionController.refresh();
        print('Reset collector subscription controller');
      } catch (e) {
        print('Error resetting collector subscription controller: $e');
      }
      
      // Reset collector application controller
      try {
        final applicationController = ref.read(collectorApplicationControllerProvider.notifier);
        // Clear any cached application data
        applicationController.clearApplication();
        print('Reset collector application controller');
      } catch (e) {
        print('Error resetting collector application controller: $e');
      }
      
      // Clear drops data
      try {
        final dropsController = ref.read(dropsControllerProvider.notifier);
        dropsController.clearDrops();
        print('Cleared drops data');
      } catch (e) {
        print('Error clearing drops data: $e');
      }
      
      // Clear notification service
      try {
        final notificationService = ref.read(notificationServiceProvider);
        notificationService.clearNotifications();
        print('Cleared notification service');
      } catch (e) {
        print('Error clearing notification service: $e');
      }
      
      // Set state to null (logged out)
      state = const AsyncValue.data(null);
      print('Logout completed successfully');
    } catch (e) {
      print('Error during logout: $e');
      // Even if there's an error, try to clear auth data
      try {
        await _prefs.remove(_tokenKey);
        await _prefs.remove(_authKey);
        await _prefs.setBool(_isLoggedInKey, false);
      } catch (e2) {
        print('Secondary error clearing local auth data: $e2');
      }
      state = const AsyncValue.data(null);
    }
  }

  Future<void> refreshUserData() async {
    try {
      print('🔄 AuthProvider: Refreshing user data from server...');
      
      final response = await _authRepository.refreshUserData();
      
      response.when(
        success: (user, token, message) {
          print('✅ AuthProvider: User data refreshed successfully');
          print('🔄 AuthProvider: New user roles: ${user?.roles}');
          
          if (user != null) {
            // Update the state with new user data
            state = AsyncValue.data(user);
            
            // Save the updated user data
            _saveAuth(user);
            
            // Update user mode based on new roles
            _setUserModeFromRoles(user.roles);
            
            print('✅ AuthProvider: User data and mode updated successfully');
          }
        },
        error: (message, statusCode) {
          print('❌ AuthProvider: Failed to refresh user data: $message (Status: $statusCode)');
          if (statusCode == 401) {
            // Token expired, logout the user
            print('🔐 AuthProvider: Token expired, logging out user');
            // Note: We can't call logout here as it requires a WidgetRef
            // The user will need to manually logout or restart the app
          }
        },
      );
    } catch (e) {
      print('❌ AuthProvider: Error refreshing user data: $e');
    }
  }

  // WebSocket notification methods
  void _connectToNotifications(String token, WidgetRef ref) {
    try {
      print('🔌 AuthProvider: Setting up WebSocket connection...');
      final notificationService = ref.read(notificationServiceProvider);
      
      // Set up force logout callback
      notificationService.onForceLogout = (reason) {
        print('🚪 Force logout received: $reason');
        // Show a dialog and then logout
        handleForceLogout(reason);
      };
      
      // Connect to WebSocket
      print('🔌 AuthProvider: Calling notificationService.connect()...');
      notificationService.connect(token);
      print('🔌 AuthProvider: WebSocket connection initiated');
      
      // Check connection status after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        final isConnected = notificationService.isConnected;
        print('🔌 AuthProvider: WebSocket connection status after 2s: $isConnected');
      });
      
    } catch (e) {
      print('❌ AuthProvider: Error connecting to notifications: $e');
    }
  }

  /// Connect to WebSocket on app startup (without WidgetRef)
  void _connectToNotificationsOnStartup(String token) {
    try {
      print('🔌 AuthProvider: Setting up WebSocket connection on startup...');
      print('🔌 AuthProvider: Token length: ${token.length}');
      final notificationService = _ref.read(notificationServiceProvider);
      
      // Set up force logout callback
      notificationService.onForceLogout = (reason) {
        print('🚪 Force logout received on startup: $reason');
        print('🚪 AuthProvider: About to call handleForceLogout');
        // Show a dialog and then logout
        handleForceLogout(reason);
        print('🚪 AuthProvider: handleForceLogout completed');
      };
      
      // Connect to WebSocket
      print('🔌 AuthProvider: Calling notificationService.connect() on startup...');
      notificationService.connect(token);
      print('🔌 AuthProvider: WebSocket connection initiated on startup');
      
      // Check connection status after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        final isConnected = notificationService.isConnected;
        print('🔌 AuthProvider: WebSocket connection status after 2s: $isConnected');
        if (!isConnected) {
          print('❌ AuthProvider: WebSocket failed to connect on startup');
        }
      });
      
    } catch (e) {
      print('❌ AuthProvider: Error connecting to notifications on startup: $e');
    }
  }

  void _disconnectFromNotifications(WidgetRef ref) {
    try {
      final notificationService = ref.read(notificationServiceProvider);
      notificationService.disconnect();
      print('🔌 Disconnected from WebSocket notifications');
    } catch (e) {
      print('❌ Error disconnecting from notifications: $e');
    }
  }

  void handleForceLogout(String reason) {
    print('🚪 Handling force logout: $reason');
    print('🚪 AuthProvider: handleForceLogout called with reason: $reason');
    
    // Show force logout notification immediately
    try {
      LocalNotificationService().showForceLogoutNotification(reason: reason);
      print('🔔 Force logout notification sent');
    } catch (e) {
      print('❌ Error showing force logout notification: $e');
    }
    
    // Store the force logout reason to show dialog
    _pendingForceLogoutReason = reason;
    print('🚪 Force logout reason stored: $reason');
    print('🚪 AuthProvider: _pendingForceLogoutReason set to: $_pendingForceLogoutReason');
    
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
      print('🚪 AuthProvider: State updated to trigger auth listener');
    }
    
    // Don't clear auth data immediately - let user see the warning first
    print('🚪 Force logout initiated - waiting for user acknowledgment');
  }

  /// Get pending force logout reason and clear it
  String? getPendingForceLogoutReason() {
    final reason = _pendingForceLogoutReason;
    _pendingForceLogoutReason = null;
    return reason;
  }

  /// Execute the actual force logout after user acknowledges
  void executeForceLogout() {
    print('🚪 Executing force logout after user acknowledgment');
    
    // Clear all data immediately and set state to null
    _clearAuthAndSetState();
    
    print('🚪 Force logout completed successfully');
  }

  String? _pendingForceLogoutReason;

  /// Clear auth data and set state to null immediately
  void _clearAuthAndSetState() async {
    // Set state to null immediately first
    state = const AsyncValue.data(null);
    print('✅ Auth state set to null immediately');
    
    try {
      print('=== Before Clearing Auth Data ===');
      print('Token: ${_prefs.getString(_tokenKey)}');
      print('Auth Data: ${_prefs.getString(_authKey)}');
      print('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      print('Clearing auth data and token...');
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_authKey);
      await _prefs.setBool(_isLoggedInKey, false);
      
      print('=== After Clearing Auth Data ===');
      print('Token: ${_prefs.getString(_tokenKey)}');
      print('Auth Data: ${_prefs.getString(_authKey)}');
      print('Is Logged In: ${_prefs.getBool(_isLoggedInKey)}');
      
      print('Auth data and token cleared successfully');
      
    } catch (e) {
      print('Error clearing auth data: $e');
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

    print('setupProfile: Sending data:');
    print('  name: $name');
    print('  phone: $phone');
    print('  address: $address');
    print('  profilePhoto: $profilePhoto');

    final response = await _authRepository.setupProfile(
      name: name,
      phoneNumber: phone,
      address: address,
      profilePhoto: profilePhoto,
    );

    print('setupProfile: Response: $response');

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

        print('setupProfile: Updated user id=${updatedUser.id}');
        print('setupProfile: name=${updatedUser.name}, phone=${updatedUser.phoneNumber}');
        print('setupProfile: address=${updatedUser.address}, photo=${updatedUser.profilePhoto}');
        print('setupProfile: isProfileComplete=${updatedUser.isProfileComplete}');

        state = AsyncValue.data(updatedUser);
        await _saveAuth(updatedUser);

        if (token != null && token.isNotEmpty) {
          print('setupProfile: Saving new token after profile setup');
          await _saveToken(token);
        }

        print('setupProfile: State and storage updated');
      },
      error: (message, _) {
        print('setupProfile: Error from backend: $message');
        state = AsyncValue.error(message, StackTrace.current);
        throw Exception(message);
      },
    );
  } catch (e, stack) {
    print('setupProfile: Exception: $e');
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

      print('updateProfile: Sending data:');
      print('  name: $name');
      print('  phone: $phone');
      print('  address: $address');
      print('  profilePhoto: $profilePhoto');

      final response = await _authRepository.updateProfile(
        name: name,
        phoneNumber: phone,
        address: address,
        profilePhoto: profilePhoto,
      );
      print('updateProfile: Response: $response');

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
            print('updateProfile: Updated user with ID: ${updatedUser.id}');
            print('updateProfile: Updated user phone: ${updatedUser.phoneNumber}');
            print('updateProfile: Updated user name: ${updatedUser.name}');
            print('updateProfile: Updated user address: ${updatedUser.address}');
            print('updateProfile: Updated user profilePhoto: ${updatedUser.profilePhoto}');
            state = AsyncValue.data(updatedUser);
            _saveAuth(updatedUser);
            
            // Save new token if provided
            if (token != null) {
              print('updateProfile: Saving new token after profile update');
              _saveToken(token);
            }
            
            print('updateProfile: State and SharedPreferences updated.');
          } else {
            print('updateProfile: Success but user is null!');
            throw Exception('Profile update succeeded but user is null');
          }
        },
        error: (message, _) {
          print('updateProfile: Error from backend: $message');
          state = AsyncValue.error(message, StackTrace.current);
          throw Exception(message);
        },
      );
    } catch (e, stack) {
      print('updateProfile: Exception: $e');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
  

  Future<AuthResponse> verifyOtp(String email, String otp) async {
    try {
      print('Verifying OTP for email: $email');
      final response = await _authRepository.verifyOtp(email: email, otp: otp);
      print('OTP verification response: $response');
      
      response.when(
        success: (user, token, message) {
          print('OTP verification success - User: $user, Token: $token');
          if (token != null && user != null) {
            print('Saving user data and token after OTP verification');
            print('User ID from backend: ${user.id}');
            _saveAuth(user);
            _saveToken(token);
            _setUserModeFromRoles(user.roles);
            state = AsyncValue.data(user);
          } else if (token != null && user == null) {
            print('Creating new user object with token (fallback)');
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
            print('Saving user data and token after OTP verification');
            _saveAuth(newUser);
            _saveToken(token);
            _setUserModeFromRoles(newUser.roles);
            state = AsyncValue.data(newUser);
          } else {
            print('Warning: No token received after OTP verification');
            state = AsyncValue.error('Invalid verification response', StackTrace.current);
          }
        },
        error: (message, statusCode) {
          print('OTP verification error: $message (Status: $statusCode)');
          state = AsyncValue.error(message, StackTrace.current);
        },
      );
      return response;
    } catch (e, stackTrace) {
      print('Error in verifyOtp: $e');
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
      print('Handling session expiration...');
      
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
      print('Session expiration handled successfully');
    } catch (e) {
      print('Error handling session expiration: $e');
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
          print('Session is still valid');
        },
        error: (message, statusCode) async {
          if (statusCode == 401) {
            print('Session expired detected');
            await _handleSessionExpiration();
          }
        },
      );
    } catch (e) {
      print('Error checking session expiration: $e');
    }
  }

  Future<void> _handleSessionExpiration() async {
    try {
      print('Handling session expiration...');
      
      // Clear all cached data
      await _clearAuth();
      
      // Clear user mode
      final userModeController = _ref.read(userModeControllerProvider.notifier);
      await userModeController.clearMode();
      
      // Update state
      state = const AsyncValue.data(null);
      
      print('Session expiration handled successfully');
    } catch (e) {
      print('Error handling session expiration: $e');
    }
  }

  Future<AuthResponse> checkSessionValidity() async {
    try {
      final currentUser = state.value;
      if (currentUser == null) {
        return AuthResponse.error(message: 'No user logged in', statusCode: 401);
      }

      print('Checking session validity...');
      
      // Get fresh user data from backend
      final response = await _authRepository.getProfile();
      
      return response;
    } catch (e) {
      print('Error checking session validity: $e');
      return AuthResponse.error(message: 'Session check failed: $e', statusCode: 500);
    }
  }

  Future<void> handleGlobal401Error(BuildContext context) async {
    try {
      print('Handling global 401 error...');
      
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
      print('Global 401 error handled successfully');
    } catch (e) {
      print('Error handling global 401 error: $e');
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
    print('🔄 AuthProvider: Updating collector application status to: $status');
    
    state.whenData((userData) {
      if (userData != null) {
        final updatedUserData = UserData(
          id: userData.id,
          email: userData.email,
          name: userData.name,
          phoneNumber: userData.phoneNumber,
          address: userData.address,
          profilePhoto: userData.profilePhoto,
          roles: status == auth_models.CollectorApplicationStatus.approved 
              ? [...userData.roles, 'collector']
              : userData.roles,
          collectorSubscriptionType: userData.collectorSubscriptionType,
          createdAt: userData.createdAt,
          updatedAt: userData.updatedAt,
          isProfileComplete: userData.isProfileComplete,
          isDeleted: userData.isDeleted,
          deletedAt: userData.deletedAt,
          deletedBy: userData.deletedBy,
          sessionInvalidatedAt: userData.sessionInvalidatedAt,
          collectorApplicationStatus: status,
          collectorApplicationId: applicationId,
          collectorApplicationAppliedAt: appliedAt,
          collectorApplicationReviewedAt: reviewedAt,
          collectorApplicationRejectionReason: rejectionReason,
        );
        // Update state
        state = AsyncValue.data(updatedUserData);
        
        // Save to shared preferences
        _saveAuth(updatedUserData);
        
        print('🔄 AuthProvider: Application status updated successfully');
      }
    });
  }

  // Clear application status (when user applies again after rejection)
  void clearCollectorApplicationStatus() {
    print('🔄 AuthProvider: Clearing collector application status');
    
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
        
        print('🔄 AuthProvider: Application status cleared successfully');
      }
    });
  }

  // Set up application status update callback
  void _setupApplicationStatusCallback() {
    final notificationService = _ref.read(notificationServiceProvider);
    notificationService.onApplicationStatusUpdate = (status, data) {
      print('🔄 AuthProvider: Application status update received: $status');
      
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
    print('🔄 AuthProvider: Syncing application status from database...');
    
    try {
      // Get the current user ID
      final currentUser = state.value;
      if (currentUser == null) {
        print('🔄 AuthProvider: No current user, skipping sync');
        return;
      }

      // Check if user already has application status in shared preferences
      final existingStatus = currentUser.collectorApplicationStatus;
      final existingApplicationId = currentUser.collectorApplicationId;
      print('🔄 AuthProvider: Current application status in shared preferences: $existingStatus');
      print('🔄 AuthProvider: Current application ID in shared preferences: $existingApplicationId');

      // Always sync from database to ensure we have the latest status
      print('🔄 AuthProvider: Fetching latest application status from database...');
        
        // Fetch application status from database
        final collectorApplicationController = _ref.read(collectorApplicationControllerProvider.notifier);
        await collectorApplicationController.getMyApplication();
        
        final applicationAsync = _ref.read(collectorApplicationControllerProvider);
        final application = applicationAsync.value;
        
        if (application != null) {
          print('🔄 AuthProvider: Found application in database: ${application.status}');
          
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
          
          print('🔄 AuthProvider: Application status synced successfully');
        } else {
          print('🔄 AuthProvider: No application found in database, clearing existing status');
          // Clear existing status if no application found in database
          await _clearCollectorApplicationStatus();
        }
    } catch (e) {
      print('🔄 AuthProvider: Error syncing application status: $e');
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
      print('🔄 AuthProvider: Cleared collector application status from shared preferences');
    } catch (e) {
      print('🔄 AuthProvider: Error clearing collector application status: $e');
    }
  }
  }
  