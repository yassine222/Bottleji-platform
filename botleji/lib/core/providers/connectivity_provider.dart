import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _debugOfflineMode = false; // Debug flag to simulate offline

  Future<void> _init() async {
    final connectivity = Connectivity();
    // Initial check
    final results = await connectivity.checkConnectivity();
    state = _isOnline(results);

    // Listen for changes
    _subscription = connectivity.onConnectivityChanged.listen((results) {
      // Only update if not in debug mode
      if (!_debugOfflineMode) {
        state = _isOnline(results);
      }
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    // If debug offline mode is enabled, always return false
    if (_debugOfflineMode) return false;
    
    // Consider online if any of the results is wifi or mobile or ethernet
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  // Debug method to simulate offline mode
  void toggleDebugOfflineMode() {
    _debugOfflineMode = !_debugOfflineMode;
    // Force a state update by setting the state directly
    state = !_debugOfflineMode;
  }

  bool get isDebugOfflineMode => _debugOfflineMode;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});



