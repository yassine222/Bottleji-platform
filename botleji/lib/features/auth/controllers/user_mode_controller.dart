import 'package:riverpod/riverpod.dart';
import 'package:botleji/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

enum UserMode {
  household,
  collector;

  String get displayName {
    switch (this) {
      case UserMode.household:
        return 'Household';
      case UserMode.collector:
        return 'Collector';
    }
  }

  String get backendRole {
    switch (this) {
      case UserMode.household:
        return 'household';
      case UserMode.collector:
        return 'collector';
    }
  }

  static UserMode fromBackendRole(String role) {
    debugPrint('Converting backend role to UserMode: $role');
    switch (role.toLowerCase()) {
      case 'household':
        return UserMode.household;
      case 'collector':
        return UserMode.collector;
      case 'user':
        return UserMode.household; // Default role from backend
      default:
        debugPrint('Unknown role: $role, defaulting to household');
        return UserMode.household;
    }
  }
}

class UserModeController extends StateNotifier<AsyncValue<UserMode>> {
  static const _userModeKey = 'user_mode';
  late final SharedPreferences _prefs;

  UserModeController() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      AppLogger.log('🔄 UserModeController: Starting initialization...');
      _prefs = await SharedPreferences.getInstance();
      AppLogger.log('✅ UserModeController: SharedPreferences initialized');
      
      // Debug: Print what's actually saved
      await debugPrintSavedMode();
      
      final mode = await _loadSavedMode();
      AppLogger.log('✅ UserModeController: Loaded mode: ${mode.name}');
      state = AsyncValue.data(mode);
      AppLogger.log('✅ UserModeController: State set to: ${mode.name}');
    } catch (e) {
      AppLogger.log('❌ UserModeController: Error initializing: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<UserMode> _loadSavedMode() async {
    AppLogger.log('🔍 UserModeController: Loading saved mode from SharedPreferences...');
    AppLogger.log('🔍 UserModeController: SharedPreferences instance: $_prefs');
    AppLogger.log('🔍 UserModeController: Key being used: $_userModeKey');
    
    // Check all keys first
    final allKeys = _prefs.getKeys();
    AppLogger.log('🔍 UserModeController: All SharedPreferences keys: $allKeys');
    
    final savedMode = _prefs.getString(_userModeKey);
    AppLogger.log('🔍 UserModeController: Loading saved mode from SharedPreferences: $savedMode');
    
    if (savedMode == null) {
      AppLogger.log('🔍 UserModeController: No saved mode found, defaulting to household');
      await _prefs.setString(_userModeKey, UserMode.household.name);
      AppLogger.log('✅ UserModeController: Set default household mode in SharedPreferences');
      return UserMode.household;
    }

    try {
      final mode = UserMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => UserMode.household,
      );
      AppLogger.log('✅ UserModeController: Successfully loaded saved mode: ${mode.name}');
      return mode;
    } catch (e) {
      AppLogger.log('❌ UserModeController: Error loading saved mode: $e');
      await _prefs.setString(_userModeKey, UserMode.household.name);
      AppLogger.log('✅ UserModeController: Reset to household mode due to error');
      return UserMode.household;
    }
  }

  Future<UserMode?> getCurrentMode() async {
    try {
      final savedMode = _prefs.getString(_userModeKey);
      if (savedMode == null) {
        return null;
      }
      
      return UserMode.values.firstWhere(
        (mode) => mode.name == savedMode,
        orElse: () => UserMode.household,
      );
    } catch (e) {
      debugPrint('Error getting current mode: $e');
      return null;
    }
  }

  Future<void> setMode(UserMode mode) async {
    try {
      AppLogger.log('🔄 UserModeController: Setting user mode to: ${mode.name}');
      AppLogger.log('🔍 UserModeController: SharedPreferences instance: $_prefs');
      AppLogger.log('🔍 UserModeController: Key being used: $_userModeKey');
      
      // Check what's currently saved before setting
      final currentSaved = _prefs.getString(_userModeKey);
      AppLogger.log('🔍 UserModeController: Currently saved mode before change: $currentSaved');
      
      await _prefs.setString(_userModeKey, mode.name);
      AppLogger.log('✅ UserModeController: User mode saved to SharedPreferences: ${mode.name}');
      
      // Verify the save immediately
      final savedMode = _prefs.getString(_userModeKey);
      AppLogger.log('🔍 UserModeController: Verified saved mode: $savedMode');
      
      // Double-check by reading all keys
      final allKeys = _prefs.getKeys();
      AppLogger.log('🔍 UserModeController: All SharedPreferences keys: $allKeys');
      
      // Update state
      state = AsyncValue.data(mode);
      AppLogger.log('✅ UserModeController: State updated to: ${mode.name}');
    } catch (e) {
      AppLogger.log('❌ UserModeController: Error setting user mode: $e');
      AppLogger.log('❌ UserModeController: Error type: ${e.runtimeType}');
      AppLogger.log('❌ UserModeController: Error details: ${e.toString()}');
      // Check if it's a 401 error
      if (e.toString().contains('401')) {
        AppLogger.log('401 error in user mode controller');
        // Handle session expiration by clearing mode
        await clearMode();
      }
    }
  }

  Future<void> clearMode() async {
    try {
      AppLogger.log('🔄 UserModeController: Clearing user mode');
      await _prefs.remove(_userModeKey);
      AppLogger.log('✅ UserModeController: User mode cleared from SharedPreferences');
      state = const AsyncValue.data(UserMode.household);
      AppLogger.log('✅ UserModeController: State reset to household');
    } catch (e) {
      debugPrint('Error clearing mode: $e');
    }
  }

  Future<void> debugPrintSavedMode() async {
    try {
      final savedMode = _prefs.getString(_userModeKey);
      AppLogger.log('🔍 UserModeController: DEBUG - Saved mode in SharedPreferences: $savedMode');
      
      if (savedMode != null) {
        final mode = UserMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => UserMode.household,
        );
        AppLogger.log('🔍 UserModeController: DEBUG - Parsed mode: ${mode.name}');
      } else {
        AppLogger.log('🔍 UserModeController: DEBUG - No saved mode found');
      }
    } catch (e) {
      AppLogger.log('❌ UserModeController: DEBUG - Error reading saved mode: $e');
    }
  }

  // Helper method to check if user can switch to a specific mode
  bool canSwitchToMode(UserMode mode, List<String> userRoles) {
    return userRoles.contains(mode.backendRole);
  }

  // Helper method to get available modes for a user
  List<UserMode> getAvailableModes(List<String> userRoles) {
    final availableModes = <UserMode>[];
    
    if (userRoles.contains('household')) {
      availableModes.add(UserMode.household);
    }
    
    if (userRoles.contains('collector')) {
      availableModes.add(UserMode.collector);
    }
    
    return availableModes;
  }
}

final userModeControllerProvider = StateNotifierProvider<UserModeController, AsyncValue<UserMode>>((ref) {
  return UserModeController();
});