import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:botleji/core/api/api_client.dart';
import 'package:botleji/core/config/api_config.dart';
import 'package:botleji/core/services/local_notification_service.dart';

class ActiveCollectionIndicator extends ConsumerStatefulWidget {
  const ActiveCollectionIndicator({super.key});

  @override
  ConsumerState<ActiveCollectionIndicator> createState() => _ActiveCollectionIndicatorState();
}

class _ActiveCollectionIndicatorState extends ConsumerState<ActiveCollectionIndicator> with WidgetsBindingObserver {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _hasTimedOut = false; // Add flag to prevent multiple timeouts
  String? _lastActiveCollectionId; // Track the last active collection ID
  int _totalTimeoutSeconds = 0; // Store total timeout for recalculation
  DateTime? _timerPausedAt; // Track when timer was paused

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Only initialize timer if there's an active collection
    final activeCollection = ref.read(navigationControllerProvider);
    if (activeCollection != null) {
      _lastActiveCollectionId = activeCollection.dropId;
      _initializeTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background - pause timer
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground - recalculate and resume timer
      _resumeTimer();
    }
  }

  void _pauseTimer() {
    if (_timer != null && _timer!.isActive) {
      _timerPausedAt = DateTime.now();
      _timer?.cancel();
      debugPrint('⏰ ActiveCollectionIndicator: Timer paused at: $_timerPausedAt');
    }
  }

  void _resumeTimer() {
    // Always recalculate remaining time based on actual elapsed time when resuming
    final activeCollection = ref.read(navigationControllerProvider);
    if (activeCollection != null) {
      // If timer wasn't initialized yet, initialize it first
      if (_totalTimeoutSeconds == 0) {
        debugPrint('⏰ ActiveCollectionIndicator: Timer not initialized on resume, initializing now...');
        _initializeTimer();
        return; // _initializeTimer will handle the expired check
      }
      
      // Cancel existing timer if any
      _timer?.cancel();
      
      // Recalculate remaining time based on actual elapsed time
      final elapsed = DateTime.now().difference(activeCollection.acceptedAt).inSeconds;
      _remainingSeconds = _totalTimeoutSeconds - elapsed;
      
      // Ensure remaining time is not negative
      if (_remainingSeconds <= 0) {
        _remainingSeconds = 0;
        _hasTimedOut = true;
        debugPrint('⏰ ActiveCollectionIndicator: Timer expired while in background - elapsed: ${elapsed}s, timeout: ${_totalTimeoutSeconds}s');
        _timerPausedAt = null;
        
        // Handle timeout immediately - show popup
        _createExpiredInteraction(activeCollection);
        ref.read(navigationControllerProvider.notifier).completeCollection();
        _showTimeoutWarning(context);
        return;
      }
      
      debugPrint('⏰ ActiveCollectionIndicator: Timer resumed - Recalculated remaining time: $_remainingSeconds seconds (elapsed: ${elapsed}s)');
      _timerPausedAt = null;
      
      // Restart the timer with recalculated time
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Check if there's still an active collection
        final currentActiveCollection = ref.read(navigationControllerProvider);
        if (currentActiveCollection == null) {
          debugPrint('⏰ Active collection cleared, cancelling timer');
          timer.cancel();
          return;
        }
        
        if (_remainingSeconds > 0 && !_hasTimedOut) {
          setState(() {
            _remainingSeconds--;
          });
        } else if (_remainingSeconds <= 0 && !_hasTimedOut) {
          // Timeout reached - only handle once
          debugPrint('⏰ TIMEOUT REACHED in ActiveCollectionIndicator');
          _hasTimedOut = true;
          
          // Create expired interaction before clearing the collection
          _createExpiredInteraction(currentActiveCollection);
          
          // Clear the active collection
          ref.read(navigationControllerProvider.notifier).completeCollection();
          timer.cancel();
          
          // Show warning popup on home screen
          _showTimeoutWarning(context);
        }
      });
    }
  }

  void _initializeTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    _timerPausedAt = null; // Reset pause time
    
    // Reset timeout flag
    _hasTimedOut = false;
    
    // Check if there's an active collection
    final activeCollection = ref.read(navigationControllerProvider);
    if (activeCollection == null) {
      debugPrint('⏰ No active collection found, skipping timer initialization');
      return;
    }
    
    // Parse route duration from the active collection's route info
    int routeDurationMinutes = 15; // Default fallback - 15 minutes (more conservative)
    
    if (activeCollection.routeDuration != null && activeCollection.routeDuration!.isNotEmpty) {
      final durationText = activeCollection.routeDuration!;
      
      // Parse duration like "15 mins" or "1 hour 30 mins"
      final durationParts = durationText.split(' ');
      if (durationParts.length >= 2) {
        try {
          if (durationParts[1].contains('hour')) {
            // Format: "1 hour 30 mins" or "1 hour"
            routeDurationMinutes = int.parse(durationParts[0]) * 60;
            if (durationParts.length >= 4 && durationParts[3].contains('mins')) {
              routeDurationMinutes += int.parse(durationParts[2]);
            }
          } else {
            // Parse minutes from duration text like "15 mins"
            routeDurationMinutes = int.parse(durationParts[0]);
          }
        } catch (e) {
          debugPrint('⏰ Error parsing route duration: $e, using default 15 minutes');
          routeDurationMinutes = 15;
        }
      }
    } else {
      // When routeDuration is null (e.g., restored from backend), use a conservative default
      // Calculate elapsed time to determine a reasonable default
      final elapsed = DateTime.now().difference(activeCollection.acceptedAt);
      final elapsedMinutes = elapsed.inMinutes;
      
      // If significant time has passed, use a shorter default to avoid extending the timeout
      if (elapsedMinutes > 10) {
        // If more than 10 minutes have passed, use a shorter default (10 minutes)
        routeDurationMinutes = 10;
        debugPrint('⏰ Route duration not available, using conservative default of 10 minutes (${elapsedMinutes} minutes already elapsed)');
      } else {
        // Otherwise use standard default
        debugPrint('⏰ Route duration not available, using default of 15 minutes');
      }
    }
    
    // Fixed buffer based on route duration (same as navigation screen)
    int bufferMinutes;
    if (routeDurationMinutes <= 5) {
      bufferMinutes = 10; // Short routes: +10 minutes
    } else if (routeDurationMinutes <= 15) {
      bufferMinutes = 15; // Medium routes: +15 minutes
    } else {
      bufferMinutes = 20; // Long routes: +20 minutes
    }
    
    // Calculate total timeout based on route duration + buffer
    var totalTimeoutMinutes = routeDurationMinutes + bufferMinutes;
    
    // Calculate how much time has already passed since collection was accepted
    final timeElapsed = DateTime.now().difference(activeCollection.acceptedAt);
    final elapsedMinutes = timeElapsed.inMinutes;
    final elapsedSeconds = timeElapsed.inSeconds;
    
    // If routeDuration was null (restored from backend), ensure we don't extend the timeout
    // beyond what's reasonable. Cap the total timeout to prevent adding too much time.
    if (activeCollection.routeDuration == null || activeCollection.routeDuration!.isEmpty) {
      // If we've already elapsed significant time, cap the total timeout to prevent extending it too much
      // Maximum reasonable timeout: elapsed time + 20 minutes buffer
      final maxReasonableTimeout = elapsedMinutes + 20;
      if (totalTimeoutMinutes > maxReasonableTimeout) {
        debugPrint('⏰ Capping timeout from ${totalTimeoutMinutes}min to ${maxReasonableTimeout}min to prevent extending timeout too much');
        totalTimeoutMinutes = maxReasonableTimeout;
      }
    }
    
    _totalTimeoutSeconds = totalTimeoutMinutes * 60;
    
    // Calculate remaining time based on actual elapsed time
    _remainingSeconds = _totalTimeoutSeconds - elapsedSeconds;
    
    // Ensure remaining time is not negative
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _hasTimedOut = true;
      debugPrint('⏰ Timer already expired, setting to 0');
    }
    
    debugPrint('⏰ Active Collection Timer: ${routeDurationMinutes}min route + ${bufferMinutes}min buffer = ${totalTimeoutMinutes}min total');
    debugPrint('⏰ Time elapsed since accepted: ${elapsedMinutes}min (${elapsedSeconds}s), Remaining: ${_remainingSeconds}s');
    
    // Only start timer if not already timed out
    if (!_hasTimedOut) {
      // Start countdown timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Check if there's still an active collection
        final currentActiveCollection = ref.read(navigationControllerProvider);
        if (currentActiveCollection == null) {
          debugPrint('⏰ Active collection cleared, cancelling timer');
          timer.cancel();
          return;
        }
        
        if (_remainingSeconds > 0 && !_hasTimedOut) {
          setState(() {
            _remainingSeconds--;
          });
        } else if (_remainingSeconds <= 0 && !_hasTimedOut) {
          // Timeout reached - only handle once
          debugPrint('⏰ TIMEOUT REACHED in ActiveCollectionIndicator');
          _hasTimedOut = true;
          
          // Create expired interaction before clearing the collection
          _createExpiredInteraction(currentActiveCollection);
          
          // Clear the active collection
          ref.read(navigationControllerProvider.notifier).completeCollection();
          timer.cancel();
          
          // Show warning popup on home screen
          _showTimeoutWarning(context);
        }
      });
    } else {
      debugPrint('⏰ Timer already expired, not starting countdown');
      // Handle timeout immediately
      _createExpiredInteraction(activeCollection);
      ref.read(navigationControllerProvider.notifier).completeCollection();
      _showTimeoutWarning(context);
    }
  }

  void _createExpiredInteraction(activeCollection) async {
    try {
      debugPrint('🚀 Expiring collection attempt from ActiveCollectionIndicator...');
      debugPrint('🚀 Drop ID: ${activeCollection.dropId}');
      debugPrint('🚀 Collector ID: ${activeCollection.collectorId}');
      
      final dio = ApiClientConfig.createDio();
      
      // Find the active collection attempt for this drop
      debugPrint('🔍 Getting active collection attempt...');
      final attemptsResponse = await dio.get(
        '${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/attempts',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      final attempts = attemptsResponse.data as List;
      final activeAttempt = attempts.firstWhere(
        (a) => a['status'] == 'active',
        orElse: () => null,
      );
      
      if (activeAttempt == null) {
        debugPrint('❌ No active collection attempt found for this drop');
        return;
      }
      
      final attemptId = activeAttempt['_id'];
      debugPrint('✅ Found active attempt: $attemptId');
      
      // Complete it as expired
      debugPrint('🔄 Completing attempt as expired...');
      final completeResponse = await dio.patch(
        '${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/attempts/$attemptId/complete',
        data: {
          'outcome': 'expired',
          'notes': 'Collection expired - timer timeout',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      debugPrint('✅ Collection attempt completed as expired: ${completeResponse.statusCode}');
      debugPrint('✅ Response data: ${completeResponse.data}');
      
      // Also update the drop status back to pending
      debugPrint('🔄 Updating drop status to pending...');
      final updateResponse = await dio.patch(
        '${ApiConfig.baseUrlSync}/dropoffs/${activeCollection.dropoffId}/status',
        data: {
          'status': 'pending',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      debugPrint('✅ Drop status updated to pending: ${updateResponse.statusCode}');
    } catch (e) {
      debugPrint('❌ Error creating expired collection attempt: $e');
      debugPrint('❌ Error details: ${e.toString()}');
    }
  }

  void _showTimeoutWarning(BuildContext context) {
    // Check if there's still an active collection before showing popup
    final activeCollection = ref.read(navigationControllerProvider);
    if (activeCollection == null) {
      debugPrint('⏰ No active collection found, skipping timeout warning');
      return;
    }
    
    // Show notification for drop expiration (background method)
    debugPrint('🔔 Showing drop expired notification');
        LocalNotificationService().showDropExpiredNotificationBackground(
      dropId: activeCollection.dropId,
      dropTitle: 'Drop Collection', // You can customize this title
    );
    
    // Add a small delay to ensure we're on the home screen
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // Check again after delay
        final currentActiveCollection = ref.read(navigationControllerProvider);
        if (currentActiveCollection == null) {
          debugPrint('⏰ Active collection cleared during delay, skipping popup');
          return;
        }
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Collection Timeout'),
            content: const Text(
              'You did not complete the collection within the allocated time. '
              'This drop has been returned to the pending list and a warning has been added to your account. '
              'Please prioritize collections in the future.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }


  String _formatTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCollection = ref.watch(navigationControllerProvider);
    final userMode = ref.watch(userModeControllerProvider);
    
    // Re-initialize timer when active collection changes (e.g., restored from backend)
    if (activeCollection != null && activeCollection.dropId != _lastActiveCollectionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastActiveCollectionId = activeCollection.dropId;
        _initializeTimer();
      });
    } else if (activeCollection == null && _lastActiveCollectionId != null) {
      // Collection was cleared, cancel timer
      _lastActiveCollectionId = null;
      _timer?.cancel();
      _timer = null;
    }
    
    return userMode.when(
      data: (mode) {
        // Only show for collectors with active collection
        if (mode == UserMode.collector && activeCollection != null) {
          // Check if drawer is open by using the Scaffold's drawer state
          final scaffold = Scaffold.of(context);
          final isDrawerOpen = scaffold.hasDrawer && scaffold.isDrawerOpen;
          
          // Hide the indicator if drawer is open
          if (isDrawerOpen) {
            return const SizedBox.shrink();
          }
          
          final topPadding = MediaQuery.of(context).padding.top;
          return Positioned(
            top: (topPadding + 12).toDouble(), // Aligned with session value card
            right: 16,
            child: LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final height = renderBox.size.height;
                    debugPrint('📏 Live Collection Card Height: $height px');
                  }
                });
                return Container(
                  constraints: const BoxConstraints(
                    minHeight: 80,
                    maxHeight: 80,
                  ), // Fixed height to match Today Total card
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00695C),
                    const Color(0xFF00695C).withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    _showActiveCollectionDialog(context, activeCollection);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10), // Match Today Total card padding
                    child: SizedBox(
                      height: 60, // Fixed content height (80px container - 20px padding)
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center, // Center content vertically
                        children: [
                        // Animated red glowing indicator
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const GlowingPulseAnimation(),
                        ),
                        const SizedBox(width: 6),
                        // Text and timer
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Live Collection',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13, // Increased font size
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_formatTime(_remainingSeconds)} remaining',
                              style: TextStyle(
                                color: _remainingSeconds < 300 ? Colors.orange : Colors.white,
                                fontSize: 15, // Increased font size
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        // Icon
                        const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 16, // Keep original smaller icon
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
              );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showActiveCollectionDialog(BuildContext context, activeCollection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Collection in Progress'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drop image and map side by side
              Row(
                children: [
                  // Drop image
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: activeCollection.imageUrl != null && activeCollection.imageUrl!.isNotEmpty
                          ? Image.network(
                              activeCollection.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 60,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 60,
                              ),
                            ),
                    ),
                  ),
                  
                  // Small map with pin
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: activeCollection.destination,
                            zoom: 14.5,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId('active_drop_${activeCollection.dropId}'),
                              position: activeCollection.destination,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                              infoWindow: InfoWindow(
                                title: 'Drop Location',
                                snippet: 'Collection in progress',
                              ),
                            ),
                          },
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          compassEnabled: false,
                          rotateGesturesEnabled: false,
                          scrollGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          liteModeEnabled: true,
                          trafficEnabled: false,
                          buildingsEnabled: false,
                          indoorViewEnabled: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Drop details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drop ID: ${activeCollection.dropId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bottles: ${activeCollection.numberOfBottles}, Cans: ${activeCollection.numberOfCans}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Type: ${activeCollection.bottleType}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (activeCollection.notes != null && activeCollection.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${activeCollection.notes}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Accepted: ${_formatDateTime(activeCollection.acceptedAt)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00695C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00695C).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF00695C), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have an active collection in progress. Tap "Resume Collection" to return to navigation.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to navigation screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NavigationScreen(
                    destination: activeCollection.destination,
                    dropId: activeCollection.dropId,
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00695C), // App's green color
              foregroundColor: Colors.white,
            ),
            child: const Text('Resume Collection'),
          ),
        ],
      ),
    );
  }
}

class PulseAnimation extends StatefulWidget {
  const PulseAnimation({super.key});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 

class GlowingPulseAnimation extends StatefulWidget {
  const GlowingPulseAnimation({super.key});

  @override
  State<GlowingPulseAnimation> createState() => _GlowingPulseAnimationState();
}

class _GlowingPulseAnimationState extends State<GlowingPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(_opacityAnimation.value),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.red.withOpacity(_opacityAnimation.value * 0.5),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  }
