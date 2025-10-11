import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:botleji/core/widgets/app_drawer.dart';
import 'package:botleji/core/theme/app_colors.dart';
import 'package:botleji/features/navigation/presentation/widgets/bottom_nav_bar.dart';
import 'package:botleji/features/navigation/controllers/navigation_controller.dart';
import 'package:botleji/features/stats/presentation/screens/stats_screen.dart';
import 'package:botleji/features/tips/presentation/screens/tips_screen.dart';
import 'package:botleji/features/drops/domain/models/drop.dart';
import 'package:botleji/features/auth/controllers/user_mode_controller.dart';
import 'package:botleji/features/auth/presentation/providers/auth_provider.dart';
import 'package:botleji/features/drops/controllers/drops_controller.dart';
import 'package:botleji/features/drops/presentation/screens/drops_list_screen.dart';
import 'package:botleji/features/drops/presentation/screens/edit_drop_screen.dart';
import 'package:botleji/features/navigation/presentation/screens/navigation_screen.dart';
import 'package:botleji/core/providers/connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:botleji/features/auth/data/models/user_data.dart';
import 'package:botleji/core/theme/app_typography.dart';
import 'package:botleji/core/navigation/app_routes.dart';
import 'package:botleji/core/widgets/active_collection_indicator.dart';
import 'package:botleji/features/notifications/presentation/screens/notifications_screen.dart';


// Navigation step model
class NavigationStep {
  final String instruction;
  final String distance;
  final String duration;
  final String maneuver;
  final List<LatLng> polylinePoints;
  final String? streetName;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
    required this.polylinePoints,
    this.streetName,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _screenKey = GlobalKey(); // Add global key for screen rebuild
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  LatLng? _selectedDropLocation;
  String? _selectedLocationAddress;
  String? _currentLocationAddress;
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = true;
  bool _isMapInitialized = false;
  bool _isMapLoading = false;
  double _collectionRadius = 5.0; // Default radius in kilometers
  bool _useCurrentLocation = true;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Custom marker icon
  BitmapDescriptor? _customDropMarker;
  
  // Form fields
  int _numberOfBottles = 1;
  int _numberOfCans = 0; // Start with 0 cans since default is plastic bottles
  BottleType _bottleType = BottleType.plastic;
  String _notes = '';
  bool _leaveOutside = false;

  // Focus nodes for keyboard navigation
  final FocusNode _bottlesFocusNode = FocusNode();
  final FocusNode _cansFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();
  
  // Text editing controllers for form fields
  late TextEditingController _bottlesController;
  late TextEditingController _cansController;
  late TextEditingController _notesController;
  
  // Location state management
  bool _isLocationLocked = false; // New flag to track if location is locked

  // Forcing map rebuild on mode change
  UserMode? _lastUserMode;
  int _mapKey = 0;
  Timer? _mapRebuildTimer;
  
  // Map interaction state
  bool _isLocationConfirmed = false;
  bool _isMarkerTransitioning = false;
  bool _isMarkersLoading = false;
  bool _isDropsLoading = false; // Add this to prevent multiple loads
  Timer? _markerUpdateTimer;
  Timer? _dropsLoadDebounceTimer; // Add debounce timer for drops loading
  int _lastLoadRequestId = 0; // Add request ID to track loads
  DateTime? _lastDropsLoadTime; // Track last load time
  UserMode? _lastLoadedMode; // Track which mode drops were loaded for
  bool _hasInitializedDrops = false; // Track if drops have been initialized
  static const String _lastLoadedModeKey = 'last_loaded_mode';
  bool _isModeSwitching = false; // Track if we're in the middle of a mode switch
  static const String _isModeSwitchingKey = 'is_mode_switching';

  // Route functionality
  bool _showRoute = false;
  String? _routeDistance;
  String? _routeDuration;
  
  // Navigation functionality
  bool _isNavigationMode = false;
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  String? _nextTurnInstruction;
  String? _nextTurnDistance;
  String? _nextStreetName;

  // Helper methods for drops tracking
  void _resetDropsTracking() {
    _lastLoadedMode = null;
    _lastDropsLoadTime = null;
    _isDropsLoading = false;
    _isMarkersLoading = false;
    _isMarkerTransitioning = false;
    _hasInitializedDrops = false;
    // Don't clear mode switching flag here - let it persist across restarts
    _saveLastLoadedMode(null); // Clear saved mode
    // Don't clear mode switching flag here
    print('🔍 Home: Reset drops tracking - ready for fresh load');
  }

  Future<void> _saveLastLoadedMode(UserMode? mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode != null) {
        await prefs.setString(_lastLoadedModeKey, mode.name);
        print('🔍 Home: Saved last loaded mode: ${mode.name}');
      } else {
        await prefs.remove(_lastLoadedModeKey);
        print('🔍 Home: Cleared last loaded mode');
      }
    } catch (e) {
      print('❌ Home: Error saving last loaded mode: $e');
    }
  }

  Future<UserMode?> _loadLastLoadedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_lastLoadedModeKey);
      if (savedMode != null) {
        final mode = UserMode.values.firstWhere(
          (mode) => mode.name == savedMode,
          orElse: () => UserMode.household,
        );
        print('🔍 Home: Loaded last loaded mode: ${mode.name}');
        return mode;
      }
      print('🔍 Home: No saved last loaded mode found');
      return null;
    } catch (e) {
      print('❌ Home: Error loading last loaded mode: $e');
      return null;
    }
  }

  Future<void> _saveModeSwitchingFlag(bool isSwitching) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isModeSwitchingKey, isSwitching);
      print('🔍 Home: Saved mode switching flag: $isSwitching');
    } catch (e) {
      print('❌ Home: Error saving mode switching flag: $e');
    }
  }

  Future<bool> _loadModeSwitchingFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSwitching = prefs.getBool(_isModeSwitchingKey) ?? false;
      print('🔍 Home: Loaded mode switching flag: $isSwitching');
      return isSwitching;
    } catch (e) {
      print('❌ Home: Error loading mode switching flag: $e');
      return false;
    }
  }

  Future<void> _clearModeSwitchingFlag() async {
    _isModeSwitching = false;
    await _saveModeSwitchingFlag(false);
    print('🔍 Home: Mode switching flag cleared');
  }

  // Debounced marker update to prevent flickering
  void _debouncedMarkerUpdate() {
    _markerUpdateTimer?.cancel();
    _markerUpdateTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isMarkersLoading = false;
        });
      }
    });
  }

  // Compress and upload image to Firebase Storage
  Future<String> _uploadImageToFirebase(File imageFile) async {
    try {
      // Compress the image first
      final originalBytes = await imageFile.readAsBytes();
      
      // Try to compress the image
      Uint8List? compressedBytes;
      String? compressionError;
      
      try {
        final image = img.decodeImage(originalBytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 800); // Resize to max 800px width
          compressedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 85));
        }
      } catch (e) {
        compressionError = e.toString();
      }

      // Use compressed image if available, otherwise use original
      final bytesToUpload = compressedBytes ?? originalBytes;
      
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'drops/$timestamp.jpg';
      
      // Get reference to the file
      final fileRef = _storage.ref().child(fileName);
      
      // Set metadata for better caching
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': imageFile.path},
      );
      // Upload the file
      final uploadTask = await fileRef.putData(bytesToUpload, metadata);
      
      // Get the download URL
      final url = await fileRef.getDownloadURL();
      return url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Calculate route between two points using Google Directions API
  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    try {
      const apiKey = "AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E";
      final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          final points = route['overview_polyline']['points'];
          final steps = leg['steps'] as List;
          
          // Decode polyline points
          final polylinePoints = _decodePolyline(points);
          
          // Parse navigation steps
          final navigationSteps = <NavigationStep>[];
          for (final step in steps) {
            final stepPoints = _decodePolyline(step['polyline']['points']);
            final instruction = _cleanHtmlInstructions(step['html_instructions']);
            final distance = step['distance']['text'];
            final duration = step['duration']['text'];
            final maneuver = step['maneuver'] ?? 'straight';
            
            navigationSteps.add(NavigationStep(
              instruction: instruction,
              distance: distance,
              duration: duration,
              maneuver: maneuver,
              polylinePoints: stepPoints,
              streetName: _extractStreetName(instruction),
            ));
          }
          
          // Create polyline for the map
          final polyline = Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.blue,
            width: 8,
            points: polylinePoints,
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          );
          setState(() {
            _polylines.clear();
            _polylines.add(polyline);
            _routeDistance = leg['distance']['text'];
            _routeDuration = leg['duration']['text'];
            _showRoute = true;
            _navigationSteps = navigationSteps;
            _currentStepIndex = 0;
            _isNavigationMode = true;
            _updateNextTurnInfo();
            _mapKey++; // Force map rebuild
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Decode Google polyline string to list of LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      poly.add(p);
    }
    return poly;
  }

  // Clean HTML instructions from Google Directions API
  String _cleanHtmlInstructions(String htmlInstructions) {
    return htmlInstructions
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&nbsp;', ' ') // Replace HTML entities
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  // Extract street name from instruction
  String? _extractStreetName(String instruction) {
    // Look for "onto" or "on" followed by street name
    final ontoMatch = RegExp(r'onto\s+([^,]+)').firstMatch(instruction);
    if (ontoMatch != null) {
      return ontoMatch.group(1)?.trim();
    }
    
    final onMatch = RegExp(r'on\s+([^,]+)').firstMatch(instruction);
    if (onMatch != null) {
      return onMatch.group(1)?.trim();
    }
    
    return null;
  }

  // Update next turn information
  void _updateNextTurnInfo() {
    if (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length) {
      final currentStep = _navigationSteps[_currentStepIndex];
      _nextTurnInstruction = currentStep.instruction;
      _nextTurnDistance = currentStep.distance;
      _nextStreetName = currentStep.streetName;
      
      // Animate camera to current step in navigation mode
      if (_isNavigationMode && _mapController != null && currentStep.polylinePoints.isNotEmpty) {
        _animateToCurrentStep(currentStep);
      }
    }
  }

  // Animate camera to current navigation step
  void _animateToCurrentStep(NavigationStep step) {
  if (step.polylinePoints.isEmpty) return;

  final points = step.polylinePoints;

  // Calculate southwest and northeast bounds
  final southwest = LatLng(
    points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
    points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
  );

  final northeast = LatLng(
    points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
    points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
  );

  // Animate camera to fit bounds
  _mapController?.animateCamera(
    CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: southwest, northeast: northeast),
      50, // padding
    ),
  );
}


    // Build navigation card UI - Google Maps style
  Widget _buildNavigationCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.green,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main navigation banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Turn icon with step number
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getManeuverIcon(_navigationSteps.isNotEmpty ? _navigationSteps[_currentStepIndex].maneuver : 'straight'),
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_currentStepIndex + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Turn instructions
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nextStreetName ?? 'Continue',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (_nextTurnInstruction != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _nextTurnInstruction!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Distance badge
                  if (_nextTurnDistance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _nextTurnDistance!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Bottom navigation bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.black87,
              ),
              child: Row(
                children: [
                  // Recenter button
                  OutlinedButton.icon(
                    onPressed: () {
                      if (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length) {
                        _animateToCurrentStep(_navigationSteps[_currentStepIndex]);
                      }
                    },
                    icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                    label: const Text(
                      'Re-centre',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Route info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _routeDuration ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '${_routeDistance ?? ''} • ${_getEstimatedArrivalTime()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Exit button
                  TextButton(
                    onPressed: _clearRoute,
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get icon for maneuver type
  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return Icons.turn_left;
      case 'turn-right':
        return Icons.turn_right;
      case 'turn-slight-left':
        return Icons.turn_slight_left;
      case 'turn-slight-right':
        return Icons.turn_slight_right;
      case 'turn-sharp-left':
        return Icons.turn_sharp_left;
      case 'turn-sharp-right':
        return Icons.turn_sharp_right;
      case 'uturn-left':
      case 'uturn-right':
        return Icons.u_turn_left;
      case 'straight':
        return Icons.straight;
      default:
        return Icons.straight;
    }
  }

  // Get estimated arrival time
  String _getEstimatedArrivalTime() {
    final now = DateTime.now();
    final arrivalTime = now.add(const Duration(minutes: 5)); // Simple estimate
    return '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}';
  }

  // Show route to selected drop
  void _showRouteToDrop(Drop drop) {
    if (_currentLocation != null) {
      _calculateRoute(_currentLocation!, drop.location);
    }
  }

  // Clear route
  void _clearRoute() {
    setState(() {
      _polylines.clear();
      _showRoute = false;
      _routeDistance = null;
      _routeDuration = null;
      _isNavigationMode = false;
      _navigationSteps.clear();
      _currentStepIndex = 0;
      _nextTurnInstruction = null;
      _nextTurnDistance = null;
      _nextStreetName = null;
      _mapKey++; // Force map rebuild
    });
  }

  // Get address from coordinates using Google Maps Geocoding API
  Future<String?> _getAddressFromCoordinates(LatLng position) async {
    try {
      // Use the Google Maps API key from the profile setup screen
      const apiKey = "AIzaSyCwq4Iy4ieyeEX-i7HVsBS_PfbdJnA300E";
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final formattedAddress = result['formatted_address'];
          return formattedAddress;
        } else {
          return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        }
      } else {
        return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }
    } catch (e) {
      return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    }
  }

  @override
  void initState() {
    super.initState();
    _bottlesController = TextEditingController(text: '1');
    _cansController = TextEditingController(text: '0');
    _notesController = TextEditingController();
    _resetDropsTracking();
    _loadLastLoadedMode().then((mode) {
      _lastLoadedMode = mode;
      print('🔍 Home: Restored last loaded mode: ${mode?.name ?? 'none'}');
    });
    _loadModeSwitchingFlag().then((isSwitching) {
      _isModeSwitching = isSwitching;
      print('🔍 Home: Restored mode switching flag: $isSwitching');
    });
    _loadCustomMarker(); // Load custom marker icon
    _initializeLocation();
    _startSessionCheck();
    _checkSessionImmediately();
  }

  // Load custom marker icon from assets
  Future<void> _loadCustomMarker() async {
    try {
      // Load pre-sized 48x64px marker icon (no scaling needed)
      final BitmapDescriptor customIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration.empty,
        'assets/icons/drop-pin.png',
      );
      setState(() {
        _customDropMarker = customIcon;
      });
      debugPrint('✅ Custom drop marker loaded successfully (48x64px)');
    } catch (e) {
      debugPrint('❌ Error loading custom marker: $e');
      // Fallback to default marker if loading fails
      setState(() {
        _customDropMarker = BitmapDescriptor.defaultMarker;
      });
    }
  }

  void _checkSessionImmediately() async {
    // Check session immediately when app starts
    await Future.delayed(const Duration(seconds: 2)); // Wait a bit for auth to load
    if (mounted) {
      await _checkSessionValidity();
      
      // Also check if user mode is available and load drops
      final userMode = ref.read(userModeControllerProvider);
      userMode.whenData((mode) async {
        print('🔍 Home: Initial user mode check: ${mode.name}');
        if (mounted && _currentLocation != null && !_hasInitializedDrops) {
          // Check if we're in the middle of a mode switch
          if (_isModeSwitching) {
            print('🔍 Home: Mode switch in progress, checking if drops need to be loaded for: ${mode.name}');
            
            // For household mode, always load drops since they show different data
            if (mode == UserMode.household) {
              print('🔍 Home: Switching to household mode, loading drops for user');
              _hasInitializedDrops = true;
              await _clearModeSwitchingFlag(); // Clear flag
              _forceLoadDropsForMap(); // Load drops for household
              return;
            } else {
              // For collector mode, skip loading since drops are already loaded
              print('🔍 Home: Mode switch in progress, skipping drops load for: ${mode.name}');
              _hasInitializedDrops = true;
              await _clearModeSwitchingFlag(); // Clear flag after using it
              return;
            }
          }
          
          // Check if drops are already loaded for this mode
          final dropsState = ref.read(dropsControllerProvider);
          final hasDropsLoaded = dropsState.maybeWhen(
            data: (drops) => drops.isNotEmpty,
            orElse: () => false,
          );
          
          if (_lastLoadedMode == mode && hasDropsLoaded) {
            print('🔍 Home: Drops already loaded and visible for mode: ${mode.name}, skipping load');
            _hasInitializedDrops = true;
          } else if (_lastLoadedMode == null || _lastLoadedMode != mode) {
            print('🔍 Home: Loading drops on app start for mode: ${mode.name} (fresh start or mode changed)');
            _hasInitializedDrops = true;
            _forceLoadDropsForMap();
          } else {
            print('🔍 Home: Mode unchanged after restart, skipping drops load for: ${mode.name}');
            _hasInitializedDrops = true; // Mark as initialized even if we skip
          }
        } else {
          print('🔍 Home: Waiting for location, not mounted, or drops already initialized');
        }
      });
    }
  }

  void _startSessionCheck() {
    // Check session validity every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _checkSessionValidity();
      }
    });
  }

  Future<void> _checkSessionValidity() async {
    try {
      final authState = ref.read(authNotifierProvider);
      if (authState.value != null) {
        // Try to get profile to check if token is still valid
        final response = await ref.read(authNotifierProvider.notifier).checkSessionValidity();
        
        response.when(
          success: (user, token, message) {
            // Session is still valid
            print('Session check: Valid');
          },
          error: (message, statusCode) {
            if (statusCode == 401) {
              print('Session expired detected');
              _showSessionExpiredDialog();
            }
          },
        );
      }
    } catch (e) {
      print('Error checking session validity: $e');
      if (e.toString().contains('401')) {
        print('Session expired detected');
        _showSessionExpiredDialog();
      }
    }
  }

 void _showSessionExpiredDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
          'Your session has expired. Please login again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Logout and navigate to login
              ref.read(authNotifierProvider.notifier).logout(ref);
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



  // Global error handler for 401 errors
  void _handleGlobal401Error() {
    print('Global 401 error detected - showing session expired dialog');
    _showSessionExpiredDialog();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force refresh auth state when dependencies change
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final authState = ref.read(authNotifierProvider);
        // debugPrint('Home screen - Auth state on dependency change: $authState');
        
        // If user ID is empty, try to reload auth state
        if (authState.value?.id == null || authState.value!.id!.isEmpty) {
          // debugPrint('Home screen - User ID is empty, attempting to reload auth state');
          
          try {
            // debugPrint('Home screen - Reloading auth state...');
            await ref.read(authNotifierProvider.notifier).refreshUserData();
            // debugPrint('Home screen - Auth state after reload: $authState');
          } catch (e) {
            // debugPrint('Home screen - Error reloading auth state: $e');
          }
        }
        
        debugPrint('Home screen - User ID on dependency change: ${authState.value?.id}');
        
        // If user ID is empty, try to reload auth state
        if (authState.value?.id == null || authState.value!.id!.isEmpty) {
          debugPrint('Home screen - User ID is empty, attempting to reload auth state');
          _reloadAuthState();
        } else {
          // User is logged in, check if we need to reload drops for the current mode
          debugPrint('Home screen - User logged in, checking if drops need to be reloaded');
          _checkAndReloadDropsForCurrentMode();
        }
      }
    });
  }

  Future<void> _reloadAuthState() async {
    try {
      debugPrint('Home screen - Reloading auth state...');
      await ref.refresh(authNotifierProvider);
      final authState = ref.read(authNotifierProvider);
      debugPrint('Home screen - Auth state after reload: $authState');
      debugPrint('Home screen - User ID after reload: ${authState.value?.id}');
    } catch (e) {
      debugPrint('Home screen - Error reloading auth state: $e');
    }
  }

  void _checkAndReloadDropsForCurrentMode() {
    final userMode = ref.read(userModeControllerProvider);
    userMode.whenData((mode) {
      // Check if drops are already loaded for this mode
      final dropsState = ref.read(dropsControllerProvider);
      final hasDropsLoaded = dropsState.maybeWhen(
        data: (drops) => drops.isNotEmpty,
        orElse: () => false,
      );
      if (_lastLoadedMode == mode && hasDropsLoaded) {
        debugPrint('Home screen - Drops already loaded for mode: ${mode.name}, skipping reload');
      } else if (_lastLoadedMode != mode) {
        debugPrint('Home screen - Mode changed, reloading drops for: ${mode.name}');
        _forceLoadDropsForMap();
      } else {
        debugPrint('Home screen - Drops not loaded for current mode: ${mode.name}, loading now');
        _forceLoadDropsForMap();
      }
    });
  }

  Future<String?> _getTokenFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token from prefs: $e');
      return null;
    }
  }

  String? _extractUserIdFromToken(String token) {
    try {
      // JWT tokens have 3 parts separated by dots
      final parts = token.split('.');
      if (parts.length != 3) {
        debugPrint('Invalid JWT token format');
        return null;
      }
      
      // Decode the payload (second part)
      final payload = parts[1];
      // Add padding if needed
      final paddedPayload = payload + '=' * (4 - payload.length % 4);
      final decoded = utf8.decode(base64Url.decode(paddedPayload));
      final payloadMap = json.decode(decoded);
      
      debugPrint('JWT payload: $payloadMap');
      final userId = payloadMap['sub'];
      debugPrint('Extracted user ID from JWT: $userId');
      
      return userId?.toString();
    } catch (e) {
      debugPrint('Error extracting user ID from token: $e');
      return null;
    }
  }

  Future<bool> _createDropWithUserId(String userId) async {
    try {
      debugPrint('Uploading image to Firebase...');
      final imageUrl = await _uploadImageToFirebase(_selectedImage!);
      debugPrint('Image uploaded successfully, URL: $imageUrl');
      debugPrint('Creating drop with user ID: $userId');
      // Read current values from controllers
      final numberOfBottles = int.tryParse(_bottlesController.text) ?? _numberOfBottles;
      final numberOfCans = int.tryParse(_cansController.text) ?? _numberOfCans;
      final notes = _notesController.text.isEmpty ? _notes : _notesController.text;
      
      debugPrint('Drop details - Bottles: $numberOfBottles, Cans: $numberOfCans, Type: $_bottleType');
      
      final dropLocation = _useCurrentLocation ? _currentLocation! : _selectedDropLocation!;
      final createdDrop = await ref.read(dropsControllerProvider.notifier).createDrop(
        userId: userId,
        imagePath: imageUrl, // Use the Firebase URL instead of local path
        numberOfBottles: numberOfBottles,
        numberOfCans: numberOfCans,
        bottleType: _bottleType,
        notes: notes.isEmpty ? "" : notes,
        leaveOutside: _leaveOutside,
        location: dropLocation,
      );
      debugPrint('Drop created successfully');
      
      // Activity tracking removed
      
      return true; // Return success
    } catch (e) {
      debugPrint('Error creating drop: $e');
      
      // Activity tracking removed
      
      return false; // Return failure
    }
  }



  @override
  void dispose() {
    _mapRebuildTimer?.cancel();
    _markerUpdateTimer?.cancel();
    _dropsLoadDebounceTimer?.cancel(); // Cancel debounce timer
    _bottlesFocusNode.dispose();
    _cansFocusNode.dispose();
    _notesFocusNode.dispose();
    _bottlesController.dispose();
    _cansController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      debugPrint('Map controller created successfully');
      setState(() {
        _mapController = controller;
        _isMapInitialized = true;
        _isMapLoading = false;
        // Initialize the collection radius circle when map is created
        if (_currentLocation != null) {
          _updateCollectionRadius(_collectionRadius);
        }
      });
      
      // If we have a current location, animate to it
      if (_currentLocation != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _mapController != null) {
            try {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(_currentLocation!, 15),
              );
            } catch (e) {
              debugPrint('Error animating camera after map creation: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error in _onMapCreated: $e');
      setState(() {
        _isMapLoading = false;
      });
      // Continue without map controller if there's an error
    }
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _isMapLoading = true;
      _errorMessage = null;
    });

    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in your device settings.';
          _isLoading = false;
          _isMapLoading = false;
        });
        return;
      }

      // Then check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Location permissions are required to show your location on the map.';
            _isLoading = false;
            _isMapLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable them in your device settings.';
          _isLoading = false;
          _isMapLoading = false;
        });
        return;
      }

      // Try to get location with retry logic
      LatLng? location = await _getLocationWithRetry();
      
      if (location == null) {
        // Try to get last known position as fallback
        try {
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            location = LatLng(lastPosition.latitude, lastPosition.longitude);
            print('🔍 Home: Using last known location as fallback');
          }
        } catch (e) {
          print('🔍 Home: Could not get last known position: $e');
        }
      }

      if (location == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to get your location. Please check your location settings and try again.';
          _isLoading = false;
          _isMapLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _isLoading = false;
        _isMapLoading = false;
        _errorMessage = null;
        // Initialize the collection radius circle when location is obtained
        _updateCollectionRadius(_collectionRadius);
      });
      
      // Get address for current location
      final address = await _getAddressFromCoordinates(_currentLocation!);
      if (mounted) {
        setState(() {
          _currentLocationAddress = address;
          // Set initial drop location to current location
          _selectedDropLocation = _currentLocation;
          _selectedLocationAddress = address;
        });
      }

      // Load drops after location is obtained
      if (mounted) {
        // Don't load drops here - already handled by app initialization
        print('🔍 Home: Location obtained, drops loading handled by app initialization');
      }

      if (_mapController != null && _isMapInitialized) {
        try {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
        } catch (e) {
          debugPrint('Error animating camera: $e');
          // Continue without camera animation if there's an error
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to get your location. Please check your location settings and try again.';
        _isLoading = false;
        _isMapLoading = false;
      });
      debugPrint('Location error: $e');
    }
  }

  /// Get location with retry logic and exponential backoff
  Future<LatLng?> _getLocationWithRetry() async {
    const int maxRetries = 3;
    const Duration initialTimeout = Duration(seconds: 5);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔍 Home: Location attempt $attempt/$maxRetries');
        
        // Use shorter timeout for faster failure detection
        final timeout = Duration(seconds: initialTimeout.inSeconds * attempt);
        
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Reduced accuracy for faster response
          timeLimit: timeout,
      );
        print('🔍 Home: Location obtained successfully on attempt $attempt');
        return LatLng(position.latitude, position.longitude);
        
      } catch (e) {
        print('🔍 Home: Location attempt $attempt failed: $e');
        
        if (attempt == maxRetries) {
          print('🔍 Home: All location attempts failed');
          return null;
        }
        
        // Wait before retry with exponential backoff
        final delay = Duration(milliseconds: 500 * attempt);
        print('🔍 Home: Waiting ${delay.inMilliseconds}ms before retry');
        await Future.delayed(delay);
      }
    }
    
    return null;
  }

  // Force load drops (bypasses debounce)
  void _forceLoadDropsForMap() {
    print('🔍 Home: Force loading drops (bypassing debounce)');
    _dropsLoadDebounceTimer?.cancel();
    _lastLoadedMode = null; // Clear last loaded mode to force fresh load
    _loadDropsForMap();
  }

  // Debounced version of _loadDropsForMap to prevent rapid successive calls
  void _debouncedLoadDropsForMap() {
    // Check if we loaded drops recently (within last 1 second instead of 2)
    if (_lastDropsLoadTime != null && 
        DateTime.now().difference(_lastDropsLoadTime!).inMilliseconds < 1000) {
      print('🔍 Home: Skipping drops load - last load was ${DateTime.now().difference(_lastDropsLoadTime!).inMilliseconds}ms ago');
      return;
    }
    
    _dropsLoadDebounceTimer?.cancel();
    _dropsLoadDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        _loadDropsForMap();
      }
    });
  }

  Future<void> _loadDropsForMap() async {
  // Prevent multiple simultaneous loads
  if (_isDropsLoading) {
    print('🔍 Home: Drops already loading, skipping...');
    return;
  }

  final requestId = ++_lastLoadRequestId;
  print('🔍 Home: Starting drops load request #$requestId');

  try {
    _isDropsLoading = true;
    print('🔍 Home: Loading drops for map... (request #$requestId)');

    final userMode = ref.read(userModeControllerProvider);
    final authState = ref.read(authNotifierProvider);

    // Wait for user mode to be available
    await userMode.when(
      data: (mode) async {
        print('🔍 Home: Processing user mode: $mode (request #$requestId)');

        // Check if drops are already loaded for this mode
        if (_lastLoadedMode == mode) {
          print('🔍 Home: Drops already loaded for mode: ${mode.name}, skipping load');
          return;
        }

        print('🔍 Home: Loading drops for mode: ${mode.name} (request #$requestId)');

        if (mode == UserMode.collector) {
          // Load only available drops for collectors (pending and cancelled, not suspicious)
          final collectorId = authState.value?.id;
          print('🔍 Home: Loading drops for collector: $collectorId (request #$requestId)');

          await ref.read(dropsControllerProvider.notifier).loadDropsAvailableForCollectors(
            excludeCollectorId: collectorId,
          );
        } else if (mode == UserMode.household) {
          if (authState.value?.id != null && authState.value!.id!.isNotEmpty) {
            print('🔍 Home: Loading drops for household: ${authState.value!.id} (request #$requestId)');

            setState(() {
              _isDropsLoading = true;
            });

            await ref.read(dropsControllerProvider.notifier).loadUserDrops(authState.value!.id!);
            print('🔍 Home: Household drops loaded successfully (request #$requestId)');
          } else {
            print('🔍 Home: No user ID found, clearing drops (request #$requestId)');

            ref.read(dropsControllerProvider.notifier).clearDrops();
          }
        }

        // Update the last loaded mode
        _lastLoadedMode = mode;
        await _saveLastLoadedMode(mode);
        print('🔍 Home: Updated last loaded mode to: ${mode.name}');
      },
      loading: () async {
        print('🔍 Home: User mode loading, waiting...');
        await Future.delayed(const Duration(seconds: 1));
        _debouncedLoadDropsForMap();
      },
      error: (error, stack) async {
        print('❌ Home: User mode error: $error');
        await Future.delayed(const Duration(seconds: 2));
        _debouncedLoadDropsForMap();
      },
    );

    // Small delay to ensure state updates
    await Future.delayed(const Duration(milliseconds: 100));
  } catch (e) {
    print('❌ Home: Error loading drops for map: $e');
  } finally {
    _isDropsLoading = false;
    _isMarkerTransitioning = false;
    _lastDropsLoadTime = DateTime.now();
    print('🔍 Home: Drops loading completed (request #$requestId)');

    if (mounted) {
      setState(() {
        _isMarkersLoading = false;
      });
    }
  }
}


  Widget _getPage(int index) {
  final userMode = ref.watch(userModeControllerProvider);

  return userMode.when(
    data: (mode) {
      switch (index) {
        case 0:
          return mode == UserMode.household
              ? _buildHouseholdHomeContent()
              : _buildCollectorHomeContent();
        case 1:
          return const DropsListScreen();
        case 2:
          return const TipsScreen();
        case 3:
          return const StatsScreen();
        default:
          return const Center(child: Text('Invalid Page'));
      }
    },
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(
      child: Text('Error loading user mode: $error'),
    ),
  );
}


  Widget _buildHouseholdHomeContent() {
  return Stack(
    children: [
      if (_errorMessage != null)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'This helps us show nearby drops and provide accurate collection services.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_errorMessage?.contains('settings') == true)
                      FilledButton.icon(
                        onPressed: () async {
                          await Geolocator.openAppSettings();
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          await _initializeLocation();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    FilledButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        await _initializeLocation();
                        if (mounted) {
                          await _loadDropsForMap();
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Reload Map'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
      else if (_isLoading)
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Getting your location...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'This helps us show nearby drops',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        )
      else
        Consumer(
          builder: (context, ref, child) {
            final userModeAsync = ref.watch(userModeControllerProvider);
            userModeAsync.whenData((mode) {
              if (_lastUserMode != mode) {
                setState(() {
                  _lastUserMode = mode;
                  _isMarkerTransitioning = true;
                  _isMarkersLoading = true;

                  if (mode == UserMode.household) {
                    _polylines.clear();
                    _showRoute = false;
                    _routeDistance = null;
                    _routeDuration = null;
                  }

                  if (mode == UserMode.collector) {
                    _updateCollectionRadius(_collectionRadius);
                  }
                });

                if (mounted) {
                  _debouncedMarkerUpdate();
                }

                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) _isMarkerTransitioning = false;
                });

                _debouncedLoadDropsForMap();
              }
            });

            ref.watch(userModeControllerProvider).whenData((mode) {
              _updateCollectionRadius(_collectionRadius);
            });

            final dropsState = ref.watch(dropsControllerProvider);
            final userMode = ref.watch(userModeControllerProvider);

            final circles = userMode.maybeWhen(
              data: (mode) {
                if (mode == UserMode.collector && _currentLocation != null) {
                  return {
                    Circle(
                      circleId: const CircleId('collection_radius'),
                      center: _currentLocation!,
                      radius: _collectionRadius * 1000,
                      fillColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      strokeColor: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  };
                }
                return <Circle>{};
              },
              orElse: () => <Circle>{},
            );

            final dropMarkers = dropsState.maybeWhen(
              data: (drops) {
                if (_isMarkersLoading || _isDropsLoading) return <Marker>{};

                final filteredDrops = userMode.maybeWhen(
                  data: (mode) {
                    if (mode == UserMode.collector) return drops;
                    return drops
                        .where((drop) =>
                            drop.userId == ref.read(authNotifierProvider).value?.id)
                        .toList();
                  },
                  orElse: () => drops,
                );

                return filteredDrops
                    .map((drop) => Marker(
                          markerId: MarkerId('drop_${drop.id}'),
                          position: drop.location,
                          icon: _customDropMarker ?? BitmapDescriptor.defaultMarker,
                          infoWindow: InfoWindow(
                            title: '${drop.numberOfBottles + drop.numberOfCans} items',
                            snippet: '${drop.bottleType.name} - ${drop.status.name}',
                          ),
                          onTap: () => _showDropDetails(drop),
                        ))
                    .toSet();
              },
              loading: () => <Marker>{},
              error: (error, stack) => <Marker>{},
              orElse: () => <Marker>{},
            );

            return Stack(
              children: [
                if (_currentLocation != null && !_isMapLoading)
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: _isNavigationMode ? 16 : 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _isNavigationMode ? {} : dropMarkers,
                    circles: _isNavigationMode ? {} : circles,
                    polylines: _polylines,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    padding: const EdgeInsets.only(bottom: 100), // Add padding for floating nav bar
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
    ],
  );
}


  void _updateCollectionRadius(double radius) {
    setState(() {
      _collectionRadius = radius;
    });
  }

  Widget _buildCollectorHomeContent() {
  return Stack(
    children: [
      if (_errorMessage != null)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _initializeLocation,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        )
      else if (_isLoading)
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Getting your location...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'This helps us show nearby drops',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        )
      else if (_currentLocation != null)
        Consumer(
          builder: (context, ref, child) {
            final dropsState = ref.watch(dropsControllerProvider);
            final userMode = ref.watch(userModeControllerProvider);

            final circles = userMode.maybeWhen(
              data: (mode) {
                if (mode == UserMode.collector && _currentLocation != null) {
                  return {
                    Circle(
                      circleId: const CircleId('collection_radius'),
                      center: _currentLocation!,
                      radius: _collectionRadius * 1000,
                      fillColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      strokeColor: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  };
                }
                return <Circle>{};
              },
              orElse: () => <Circle>{},
            );

            final dropMarkers = dropsState.maybeWhen(
              data: (drops) {
                if (_isMarkersLoading || _isDropsLoading) return <Marker>{};

                final filteredDrops = userMode.maybeWhen(
                  data: (mode) {
                    if (mode == UserMode.collector) return drops;
                    return drops
                        .where((drop) =>
                            drop.userId ==
                            ref.read(authNotifierProvider).value?.id)
                        .toList();
                  },
                  orElse: () => drops,
                );

                return filteredDrops
                    .map((drop) => Marker(
                          markerId: MarkerId('drop_${drop.id}'),
                          position: drop.location,
                          icon: _customDropMarker ?? BitmapDescriptor.defaultMarker,
                          infoWindow: InfoWindow(
                            title:
                                '${drop.numberOfBottles + drop.numberOfCans} items',
                            snippet: '${drop.bottleType.name} - ${drop.status.name}',
                          ),
                          onTap: () => _showDropDetails(drop),
                        ))
                    .toSet();
              },
              loading: () => <Marker>{},
              error: (error, stack) => <Marker>{},
              orElse: () => <Marker>{},
            );

            return Stack(
              children: [
                if (!_isMapLoading)
                  GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: _isNavigationMode ? 16 : 15,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _isNavigationMode ? {} : dropMarkers,
                    circles: _isNavigationMode ? {} : circles,
                    polylines: _polylines,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    minMaxZoomPreference: const MinMaxZoomPreference(10, 20),
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    padding: const EdgeInsets.only(bottom: 100), // Add padding for floating nav bar
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
    ],
  );
}


  double _getMarkerHue(DropStatus status) {
    switch (status) {
      case DropStatus.pending:
        return BitmapDescriptor.hueOrange;
      case DropStatus.accepted:
        return BitmapDescriptor.hueGreen;
      case DropStatus.collected:
        return BitmapDescriptor.hueBlue;
      case DropStatus.cancelled:
        return BitmapDescriptor.hueRed;
      case DropStatus.expired:
        return BitmapDescriptor.hueRed;
    }
  }

  void _showDropDetails(Drop drop) async {
    // Calculate distance if we have current location
    double? distanceInMeters;
    String? distanceText;
    String? durationText;
    
    if (_currentLocation != null) {
      distanceInMeters = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        drop.location.latitude,
        drop.location.longitude,
      );
      
      // Format distance
      if (distanceInMeters < 1000) {
        distanceText = '${distanceInMeters.toStringAsFixed(0)}m';
      } else {
        distanceText = '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
      }
      
      // Estimate duration (assuming walking speed of 5 km/h)
      final durationMinutes = (distanceInMeters / 1000 / 5 * 60).round();
      if (durationMinutes < 60) {
        durationText = '${durationMinutes}min';
      } else {
        final hours = (durationMinutes / 60).floor();
        final mins = durationMinutes % 60;
        durationText = '${hours}h ${mins}min';
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<Map<String, dynamic>?>(
        future: ref.read(dropsControllerProvider.notifier).getUserInfo(drop.userId),
        builder: (context, snapshot) {
          final userData = snapshot.data ?? {
            'name': 'Unknown User',
            'phoneNumber': 'N/A',
            'profilePhoto': null,
          };

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status badge removed (now shown on image overlay)
                          const SizedBox(height: 8),
                          
                          // User Information Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Information',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 25,
                                      backgroundImage: userData['profilePhoto'] != null
                                          ? NetworkImage(userData['profilePhoto'])
                                          : null,
                                      child: userData['profilePhoto'] == null
                                          ? const Icon(Icons.person, size: 30)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userData['name'] ?? 'Unknown User',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            userData['phoneNumber'] ?? 'N/A',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Drop Information Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Drop Information',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Bottle Type', drop.bottleType.name.toUpperCase()),
                                _buildInfoRow('Plastic Bottles', '${drop.numberOfBottles}'),
                                _buildInfoRow('Cans', '${drop.numberOfCans}'),
                                _buildInfoRow('Total Items', '${drop.numberOfBottles + drop.numberOfCans}'),
                                _buildInfoRow('Leave Outside', drop.leaveOutside ? 'Yes' : 'No'),
                                _buildInfoRow('Created', _formatDate(drop.createdAt)),
                                
                                // Notes (if any)
                                if (drop.notes?.isNotEmpty == true) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Notes',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      drop.notes!,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Action Buttons
                          Consumer(
                            builder: (context, ref, child) {
                              final userMode = ref.watch(userModeControllerProvider);
                              final currentUserId = ref.read(authNotifierProvider).value?.id;
                              
                              return userMode.when(
                                data: (mode) {
                                  // Only show action button for pending drops
                                  if (drop.status != DropStatus.pending) return const SizedBox.shrink();
                                  
                                  // For household mode - show Edit Drop button
                                  if (mode == UserMode.household && drop.userId == currentUserId) {
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          // Navigate to edit drop screen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => EditDropScreen(drop: drop),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit),
                                        label: const Text('Edit Drop'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00695C),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // For collector mode - show Start Collection button or resume/disabled state based on active collection
                                  if (mode == UserMode.collector) {
                                    final activeCollection = ref.watch(navigationControllerProvider);
                                    // If there's an active collection
                                    if (activeCollection != null) {
                                      // If it's the same drop, show Resume Navigation
                                      if (activeCollection.dropId == drop.id) {
                                        return SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              if (context.mounted) {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => NavigationScreen(
                                                      destination: activeCollection.destination,
                                                      dropId: activeCollection.dropId,
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            icon: const Icon(Icons.navigation),
                                            label: const Text('Resume Navigation'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF00695C),
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                      // Otherwise, show info and disable starting
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.amber.shade700.withOpacity(0.5)),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: const [
                                                Icon(Icons.info_outline, color: Colors.amber),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'You already have an active collection in progress. Complete or cancel it before starting a new one.',
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: null,
                                              icon: const Icon(Icons.directions),
                                              label: const Text('Start Collection'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }

                                    // No active collection — allow starting a new one
                                    final isOnline = ref.watch(connectivityProvider);
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          if (!isOnline) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('You are offline. Please check your internet connection.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                            return;
                                          }
                                          if (currentUserId == null) return;
                                          
                                          try {
                                            // Assign collector to drop
                                            await ref.read(dropsControllerProvider.notifier)
                                                .assignCollector(drop.id, currentUserId);
                                            print('✅ Collector assigned to drop');
                                            
                                            // Start the collection - this will persist the state
                                            await ref.read(navigationControllerProvider.notifier).startCollection(
                                              destination: drop.location,
                                              dropoffId: drop.id, // Using drop.id as dropoffId for now
                                              dropId: drop.id, // Add the required dropId parameter
                                              imageUrl: drop.imageUrl,
                                              numberOfBottles: drop.numberOfBottles,
                                              numberOfCans: drop.numberOfCans,
                                              bottleType: drop.bottleType.name,
                                              notes: drop.notes,
                                              leaveOutside: drop.leaveOutside,
                                              routeDuration: null, // Will be set by navigation screen
                                              routeDistance: null, // Will be set by navigation screen
                                              collectorId: currentUserId, // Add collector ID (userId)
                                            );
                                            print('✅ Collection started and saved');
                                            
                                            // Close the modal
                                            Navigator.pop(context);
                                            
                                            // Navigate to navigation screen with required args
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => NavigationScreen(
                                                    destination: drop.location,
                                                    dropId: drop.id,
                                                  ),
                                                ),
                                              );
                                            }
                                            
                                            // Show success message
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Collection started successfully!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            print('❌ Error starting collection: $e');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error starting collection: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.directions),
                                        label: const Text('Start Collection'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF00695C),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // No action button for other cases
                                  return const SizedBox.shrink();
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabControllerProvider);
    
    // Listen to user mode changes to reload drops
    ref.listen(userModeControllerProvider, (previous, next) {
      next.whenData((mode) {
        print('🔍 Home: User mode changed to: ${mode.name}');
        
        // Only reload if mode actually changed
        if (previous?.value != mode) {
          print('🔍 Home: Mode actually changed, setting mode switching flag and reloading drops');
          _isModeSwitching = true; // Set flag to prevent reload after restart
          _saveModeSwitchingFlag(true); // Save flag to SharedPreferences
          _lastLoadedMode = null; // Clear to force fresh load for new mode
          
          if (mounted && _currentLocation != null) {
            print('🔍 Home: Force reloading drops for new mode: ${mode.name}');
            _forceLoadDropsForMap();
          }
        } else {
          print('🔍 Home: Mode unchanged, skipping drops reload');
        }
      });
    });
    
    // Listen to drops state changes to reset loading flags
    ref.listen(dropsControllerProvider, (previous, next) {
      next.whenData((drops) {
        print('🔍 Home: Drops state changed to data with ${drops.length} drops');
        if (mounted) {
          setState(() {
            _isDropsLoading = false;
            _isMarkersLoading = false;
            _isMarkerTransitioning = false; // Reset marker transitioning
          });
        }
      });
    });
    
    // Note: User mode changes are now handled by the splash screen approach
    // No need to listen for user mode changes here anymore

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00695C),
                const Color(0xFF004D40),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Menu button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bottleji',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Eco-friendly bottle collection',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Notifications button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                        ),
                        // Notification badge
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Full height content
          Container(
            key: _screenKey, // Add key to force rebuild
            child: _getPage(currentIndex),
          ),
          // Offline banner just under the app bar - positioned after content so it appears on top
          Consumer(
            builder: (context, ref, child) {
              final isOnline = ref.watch(connectivityProvider);
              if (isOnline) return const SizedBox.shrink();
              return Positioned(
                top: 8, // slight padding below app bar
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.wifi_off_rounded,
                            color: Theme.of(context).colorScheme.onError,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No Internet Connection',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Text(
                                'Some features may be unavailable',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onErrorContainer.withOpacity(0.8),
                                  fontSize: 11,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () async {
                            final connectivity = Connectivity();
                            final results = await connectivity.checkConnectivity();
                            final online = results.any((r) =>
                                r == ConnectivityResult.wifi ||
                                r == ConnectivityResult.mobile ||
                                r == ConnectivityResult.ethernet ||
                                r == ConnectivityResult.vpn);
                            if (online) {
                              ref.read(connectivityProvider.notifier).state = true;
                            }
                          },
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            size: 20,
                          ),
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            minimumSize: const Size(32, 32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Active collection indicator - will hide when drawer is open
          const ActiveCollectionIndicator(),
          // Floating action button
          if (!_isLoading && _errorMessage == null && currentIndex == 0)
            Consumer(
              builder: (context, ref, child) {
                final userMode = ref.watch(userModeControllerProvider);
                return userMode.when(
                  data: (mode) => mode == UserMode.household
                      ? Positioned(
                          bottom: 120, // Same padding as Set Collection Radius button
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FloatingActionButton.extended(
                              heroTag: 'create_drop_fab',
                              onPressed: () => _showCreateDropSheet(context),
                              label: const Text('Create Drop'),
                              icon: const Icon(Icons.add_location),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Positioned(
                          bottom:120, // Increased padding above nav bar
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FloatingActionButton.extended(
                              onPressed: () => _showSetRadiusSheet(context),
                              label: const Text('Set Collection Radius'),
                              icon: const Icon(Icons.radar),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          // Floating bottom navigation bar
          BottomNavBar(
            currentIndex: currentIndex,
            onTap: (index) => ref.read(tabControllerProvider.notifier).setTab(index),
          ),
        ],
      ),
    );
  }

  void _showCreateDropSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              _buildCreateDropHeader(context),
              const SizedBox(height: 16),
              
              // Scrollable content - Takes remaining space
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      physics: _isLocationLocked
                        ? const NeverScrollableScrollPhysics() // Lock scrolling when location is locked
                        : const ClampingScrollPhysics(), // Allow scrolling when location is not locked
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationControl(setModalState),
                          const SizedBox(height: 8),
                
                          _buildRouteControls(),
                
                          _buildLocationMap(setModalState),
                          const SizedBox(height: 16),
                
                          _buildImagePicker(setModalState),
                          const SizedBox(height: 16),
              
                          _buildBottleTypeSelector(setModalState),
                          const SizedBox(height: 16),
                          _buildQuantityInputs(),
                          const SizedBox(height: 16),
                          _buildNotesField(),
                          const SizedBox(height: 16),
                          _buildLeaveOutsideCheckbox(setModalState),
                          const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                        
              // Submit button - Fixed at bottom
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for _showCreateDropSheet
  Widget _buildCreateDropHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Create New Drop',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationControl(StateSetter setModalState) {
    return Column(
      children: [
        // Location control
        SwitchListTile(
          dense: true,
          title: const Text('Use Current Location'),
          value: _useCurrentLocation,
          onChanged: (value) {
            setModalState(() {
              _useCurrentLocation = value;
              if (value) {
                _selectedDropLocation = _currentLocation;
                _selectedLocationAddress = _currentLocationAddress;
                _isLocationLocked = false;
              } else {
                _isLocationLocked = true;
              }
            });
          },
        ),
        // Address display under the switch
        if ((_selectedLocationAddress != null && !_useCurrentLocation) || 
            (_currentLocationAddress != null && _useCurrentLocation))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _useCurrentLocation ? _currentLocationAddress! : _selectedLocationAddress!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRouteControls() {
    return Column(
      children: [
        // Route button for collectors
        if (ref.watch(userModeControllerProvider).maybeWhen(
              data: (mode) => mode == UserMode.collector,
              orElse: () => false,
            ))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _currentLocation != null && (_selectedDropLocation != null || _useCurrentLocation)
                  ? () async {
                      final destination = _useCurrentLocation ? _currentLocation! : _selectedDropLocation!;
                      await _calculateRoute(_currentLocation!, destination);
                    }
                  : null,
              icon: Icon(_showRoute ? Icons.route : Icons.directions_car),
              label: Text(_showRoute ? 'Hide Route' : 'Show Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showRoute 
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        
        // Route info display
        if (_showRoute && _routeDistance != null && _routeDuration != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.route,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Route: $_routeDistance • $_routeDuration',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLocationMap(StateSetter setModalState) {
    return Material(
      elevation: 0,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation ?? const LatLng(36.8065, 10.1815),
                  zoom: 15,
                ),
                onMapCreated: (controller) {
                  setModalState(() {
                    _mapController = controller;
                  });
                },
                onCameraMove: (position) {
                  if (!_isLocationLocked && !_useCurrentLocation) {
                    setModalState(() {
                      _isLocationLocked = true;
                    });
                  }
                },
                onTap: (latLng) async {
                  setModalState(() {
                    _selectedDropLocation = latLng;
                    _useCurrentLocation = false;
                    _isLocationLocked = true;
                  });
                  final address = await _getAddressFromCoordinates(latLng);
                  setModalState(() {
                    _selectedLocationAddress = address;
                  });
                },
                markers: {
                  Marker(
                    markerId: const MarkerId('drop_location'),
                    position: _useCurrentLocation ? _currentLocation! : (_selectedDropLocation ?? _currentLocation!),
                    draggable: true,
                    icon: _customDropMarker ?? BitmapDescriptor.defaultMarker,
                    anchor: const Offset(0.5, 1.0),
                    onDragEnd: (newPosition) async {
                      setModalState(() {
                        _selectedDropLocation = newPosition;
                        _useCurrentLocation = false;
                      });
                      final address = await _getAddressFromCoordinates(newPosition);
                      setModalState(() {
                        _selectedLocationAddress = address;
                      });
                    },
                    onDragStart: (_) {
                      setModalState(() {
                        _useCurrentLocation = false;
                        _isLocationLocked = true;
                      });
                    },
                    onDrag: (newPosition) {
                      setModalState(() {
                        _selectedDropLocation = newPosition;
                      });
                    },
                  ),
                },
                polylines: _polylines,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),
              if (_isLocationLocked && !_useCurrentLocation) ...[
                _buildMapOverlays(setModalState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapOverlays(StateSetter setModalState) {
    return Stack(
      children: [
        // Lock indicator
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                const Text(
                  'Form Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Info message
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap "Confirm" when you\'re happy with the location',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Confirm button
        Positioned(
          bottom: 8,
          right: 8,
          child: FloatingActionButton.extended(
            onPressed: () {
              setModalState(() {
                _isLocationLocked = false;
              });
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.check),
            label: const Text('Confirm'),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Photo',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Take a clear photo of your bottles to help collectors identify them easily',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final imagePicker = ImagePicker();
            final pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
            
            if (pickedFile != null) {
              setModalState(() {
                _selectedImage = File(pickedFile.path);
              });
            }
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedImage == null 
                    ? Theme.of(context).colorScheme.error 
                    : Theme.of(context).dividerColor,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _selectedImage == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _selectedImage = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottleTypeSelector(StateSetter setModalState) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<BottleType>(
        value: _bottleType,
        decoration: const InputDecoration(
          labelText: 'Bottle Type',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: BottleType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 12),
                  child: type == BottleType.plastic
                      ? Image.asset(
                          'assets/icons/water-bottle.png',
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : type == BottleType.can
                          ? Image.asset(
                              'assets/icons/can.png',
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset(
                                  'assets/icons/water-bottle.png',
                                  width: 12,
                                  height: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                Image.asset(
                                  'assets/icons/can.png',
                                  width: 12,
                                  height: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                ),
                Text(
                  type.name.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setModalState(() {
              _bottleType = value;
              if (value == BottleType.plastic) {
                _numberOfBottles = 1;
                _numberOfCans = 0;
                _bottlesController.text = '1';
                _cansController.text = '0';
              } else if (value == BottleType.can) {
                _numberOfBottles = 0;
                _numberOfCans = 1;
                _bottlesController.text = '0';
                _cansController.text = '1';
              } else if (value == BottleType.mixed) {
                _numberOfBottles = 1;
                _numberOfCans = 1;
                _bottlesController.text = '1';
                _cansController.text = '1';
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildQuantityInputs() {
    if (_bottleType == BottleType.plastic) {
      return _buildBottlesInput();
    } else if (_bottleType == BottleType.can) {
      return _buildCansInput();
    } else if (_bottleType == BottleType.mixed) {
      return Column(
        children: [
          _buildBottlesInput(),
          const SizedBox(height: 16),
          _buildCansInput(),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottlesInput() {
    return TextFormField(
      controller: _bottlesController,
      decoration: InputDecoration(
        labelText: 'Number of Plastic Bottles',
        border: const OutlineInputBorder(),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/water-bottle.png',
            width: 24,
            height: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        suffixIcon: Icon(
          Icons.recycling,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      focusNode: _bottlesFocusNode,
      onFieldSubmitted: (_) {
        _notesFocusNode.requestFocus();
      },
      validator: (value) {
        if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
          return 'Please enter a valid number';
        }
        return null;
      },
      onChanged: (value) {
        _numberOfBottles = int.tryParse(value) ?? 1;
      },
    );
  }

  Widget _buildCansInput() {
    return TextFormField(
      controller: _cansController,
      decoration: InputDecoration(
        labelText: 'Number of Cans',
        border: const OutlineInputBorder(),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/can.png',
            width: 24,
            height: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        suffixIcon: Icon(
          Icons.recycling,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      focusNode: _cansFocusNode,
      onFieldSubmitted: (_) {
        _notesFocusNode.requestFocus();
      },
      validator: (value) {
        if (value == null || int.tryParse(value) == null || int.parse(value) < 1) {
          return 'Please enter a valid number';
        }
        return null;
      },
      onChanged: (value) {
        _numberOfCans = int.tryParse(value) ?? 1;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      textInputAction: TextInputAction.done,
      focusNode: _notesFocusNode,
      onFieldSubmitted: (_) {
        _notesFocusNode.unfocus();
      },
      onChanged: (value) => _notes = value,
    );
  }

  Widget _buildLeaveOutsideCheckbox(StateSetter setModalState) {
    return CheckboxListTile(
      title: const Text('Leave outside the door'),
      value: _leaveOutside,
      onChanged: (value) {
        if (value != null) {
          setModalState(() => _leaveOutside = value);
        }
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate() && _selectedImage != null) {
            final dropLocation = _useCurrentLocation ? _currentLocation! : _selectedDropLocation!;
            _submitDrop(dropLocation);
          } else if (_selectedImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Please take a photo of your bottles'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Submit Drop',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedImage = null;
      _bottleType = BottleType.plastic;
      // Reset counts based on default bottle type
      _numberOfBottles = 1;
      _numberOfCans = 0;
      _notes = '';
      _leaveOutside = false;
      _useCurrentLocation = true;
      _selectedDropLocation = _currentLocation; // Reset to current location
      _selectedLocationAddress = _currentLocationAddress;
      _isLocationLocked = false; // Reset location lock state
    });
    
    // Reset controller text
    _bottlesController.text = '1';
    _cansController.text = '0';
    _notesController.text = '';
    
    _bottlesFocusNode.unfocus();
    _cansFocusNode.unfocus();
    _notesFocusNode.unfocus();
  }

  void _submitDrop(LatLng location) async {
    debugPrint('Starting drop submission...');
    if (_formKey.currentState!.validate() && _selectedImage != null) {
      debugPrint('Form is valid and image is selected');
      
      // Show loading dialog immediately
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.recycling,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                // Title
                Text(
                  'Creating Your Drop',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  'Compressing and uploading image...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Progress indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Ensure the dialog is shown before starting the heavy work
      await Future.delayed(const Duration(milliseconds: 100));
      // Get the current auth state
      final authState = ref.watch(authNotifierProvider);
      debugPrint('Auth state: $authState');
      
      // Check if auth state is loading
      if (authState.isLoading) {
        debugPrint('Auth state is loading, waiting...');
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please wait while we load your account information'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Check if we have a user
      if (authState == null) {
        debugPrint('Auth state is null');
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You must be logged in to create a drop'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      // Get the user from the auth state
      final user = authState.value;
      debugPrint('User from auth state: $user');
      debugPrint('User ID from auth state: ${user?.id}');
      debugPrint('User ID length: ${user?.id?.length}');
      debugPrint('User ID is empty: ${user?.id?.isEmpty}');
      debugPrint('User email from auth state: ${user?.email}');
      debugPrint('User name from auth state: ${user?.name}');
      if (user == null) {
        debugPrint('User is null');
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You must be logged in to create a drop'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      final userId = user.id;
      debugPrint('User ID from user: $userId');
      if (userId == null || userId.isEmpty) {
        debugPrint('User ID is null or empty, attempting to extract from token...');
        
        // Try to get user ID from token as fallback
        final token = await _getTokenFromPrefs();
        if (token != null) {
          final extractedUserId = _extractUserIdFromToken(token);
          debugPrint('Extracted user ID from token: $extractedUserId');
          
          if (extractedUserId != null && extractedUserId.isNotEmpty) {
            debugPrint('Using extracted user ID: $extractedUserId');
            // Continue with extracted user ID
            await _createDropWithUserId(extractedUserId);
            return;
          }
        }
        
        debugPrint('Could not extract user ID from token');
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Authentication issue detected. Please log out and log in again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Logout',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await ref.read(authNotifierProvider.notifier).logout(ref);
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                } catch (e) {
                  debugPrint('Error during logout: $e');
                }
              },
            ),
          ),
        );
        return;
      }
      
      final success = await _createDropWithUserId(userId);
      
      if (mounted) {
        // Close the loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        if (success) {
          // Close the bottom sheet
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          
          _resetForm(); // Reset form after closing modal
          
          // Don't reload drops here - they should already be loaded for the current mode
          print('🔍 Home: Drop created successfully, no need to reload drops');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Drop created successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create drop. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } else {
      debugPrint('Form validation failed or no image selected');
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please take a photo of your bottles'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
  

  void _showSetRadiusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set Collection Radius',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Set the radius (in kilometers) within which you want to collect bottles.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_collectionRadius.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Slider(
                value: _collectionRadius,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                label: '${_collectionRadius.toStringAsFixed(1)} km',
                onChanged: (value) {
                  setState(() {
                    _collectionRadius = value;
                  });
                  _updateCollectionRadius(value);
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Collection radius updated!')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save Radius'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(DropStatus status) {
    switch (status) {
      case DropStatus.pending:
        return Colors.orange;
      case DropStatus.accepted:
        return Colors.green;
      case DropStatus.collected:
        return Colors.blue;
      case DropStatus.cancelled:
        return Colors.red;
      case DropStatus.expired:
        return Colors.red;
    }
  }

  // Map interaction methods (currently unused but kept for future functionality)
  // ignore: unused_element
  void _onMapTap(LatLng latLng) {
    if (_isLocationLocked) {
      setState(() {
        _selectedDropLocation = latLng;
        _isLocationConfirmed = true;
      });
    }
  }

  // ignore: unused_element
  void _onPinDragEnd(LatLng newPosition) {
    setState(() {
      _selectedDropLocation = newPosition;
      _isLocationConfirmed = true;
    });
  }

  // ignore: unused_element
  void _onPinDragStart() {
    setState(() {
      _isLocationLocked = true;
    });
  }

  // ignore: unused_element
  void _confirmLocation() {
    if (_selectedDropLocation != null) {
      setState(() {
        _isLocationConfirmed = true;
        _isLocationLocked = false;
      });
    }
  }

  // ignore: unused_element
  void _debouncedMapRebuild() {
    _mapRebuildTimer?.cancel();
    _mapRebuildTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _mapKey++;
        });
      }
    });
  }
}