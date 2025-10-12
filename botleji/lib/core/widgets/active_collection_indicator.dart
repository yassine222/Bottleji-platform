import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:botleji/core/theme/app_colors.dart';
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

class _ActiveCollectionIndicatorState extends ConsumerState<ActiveCollectionIndicator> {
  Timer? _timer;
  int _remainingSeconds = 0;
  DateTime? _collectionStartTime;
  bool _hasTimedOut = false; // Add flag to prevent multiple timeouts

  @override
  void initState() {
    super.initState();
    // Only initialize timer if there's an active collection
    final activeCollection = ref.read(navigationControllerProvider);
    if (activeCollection != null) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    // Cancel any existing timer
    _timer?.cancel();
    
    // Reset timeout flag
    _hasTimedOut = false;
    
    // Check if there's an active collection
    final activeCollection = ref.read(navigationControllerProvider);
    if (activeCollection == null) {
      debugPrint('⏰ No active collection found, skipping timer initialization');
      return;
    }
    
    _collectionStartTime = DateTime.now();
    
    // Parse route duration from the active collection's route info
    int routeDurationMinutes = 0; // Default fallback - 20 seconds for testing
    
    if (activeCollection.routeDuration != null) {
      final durationText = activeCollection.routeDuration!;
      
      // Parse duration like "15 mins" or "1 hour 30 mins"
      if (durationText.isNotEmpty) {
        final durationParts = durationText.split(' ');
        if (durationParts.length >= 2) {
          if (durationParts[1].contains('hour')) {
            // Format: "1 hour 30 mins" or "1 hour"
            routeDurationMinutes = int.parse(durationParts[0]) * 60;
            if (durationParts.length >= 4 && durationParts[3].contains('mins')) {
              routeDurationMinutes += int.parse(durationParts[2]);
            }
          } else {
            // For testing, use 20 seconds instead of parsing minutes
            routeDurationMinutes = 0; // 20 seconds
          }
        }
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
    
    // For testing: use 1 minute total
    const totalTimeoutMinutes = 1.0; // 1 minute
    const totalTimeoutSeconds = 60; // 60 seconds for testing
    
    // Calculate how much time has already passed since collection was accepted
    final timeElapsed = DateTime.now().difference(activeCollection.acceptedAt);
    final elapsedSeconds = timeElapsed.inSeconds;
    
    // Calculate remaining time based on actual elapsed time
    _remainingSeconds = totalTimeoutSeconds - elapsedSeconds;
    
    // Ensure remaining time is not negative
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      debugPrint('⏰ Timer already expired, setting to 0');
    }
    
    debugPrint('⏰ Active Collection Timer: ${routeDurationMinutes}min route + ${bufferMinutes}min buffer = ${totalTimeoutMinutes}min total');
    debugPrint('⏰ Time elapsed since accepted: ${elapsedSeconds}s, Remaining: ${_remainingSeconds}s');
    
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
  }

  void _createExpiredInteraction(activeCollection) async {
    try {
      debugPrint('🚀 Creating expired collection attempt from ActiveCollectionIndicator...');
      debugPrint('🚀 Drop ID: ${activeCollection.dropId}');
      debugPrint('🚀 Collector ID: ${activeCollection.collectorId}');
      
      final dio = ApiClientConfig.createDio();
      
      // First, create a collection attempt (this will auto-create ACCEPTED if missing)
      debugPrint('🔄 Creating collection attempt...');
      final attemptResponse = await dio.post(
        '${ApiConfig.baseUrl}/dropoffs/${activeCollection.dropoffId}/attempts',
        data: {
          'collectorId': activeCollection.collectorId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      
      final attemptId = attemptResponse.data['_id'];
      debugPrint('✅ Collection attempt created: $attemptId');
      
      // Then complete it as expired
      debugPrint('🔄 Completing attempt as expired...');
      final completeResponse = await dio.patch(
        '${ApiConfig.baseUrl}/dropoffs/${activeCollection.dropoffId}/attempts/$attemptId/complete',
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
        '${ApiConfig.baseUrl}/dropoffs/${activeCollection.dropoffId}/status',
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

  @override
  void dispose() {
    _timer?.cancel();
    _hasTimedOut = false;
    super.dispose();
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
          
          return Positioned(
            top: MediaQuery.of(context).padding.top + 16, // Closer to app bar
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00695C), // App's green color
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _showActiveCollectionDialog(context, activeCollection);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated red glowing indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const GlowingPulseAnimation(),
                        ),
                        const SizedBox(width: 8),
                        // Text and timer
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Live Collection',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_formatTime(_remainingSeconds)} remaining',
                              style: TextStyle(
                                color: _remainingSeconds < 300 ? Colors.orange : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        // Icon
                        const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
