import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  ConsumerState<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends ConsumerState<LocationSettingsScreen> {
  bool _isLoading = true;
  LocationPermission? _locationPermission;
  bool _isLocationServiceEnabled = false;
  Position? _currentPosition;
  
  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    try {
      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      
      // Check location permission
      _locationPermission = await Geolocator.checkPermission();
      
      // Update UI immediately after checking permission/service status
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // Get current position in background if we have permission
      if (_locationPermission == LocationPermission.always || 
          _locationPermission == LocationPermission.whileInUse) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          
          if (mounted) {
            setState(() => _currentPosition = position);
          }
        } catch (e) {
          debugPrint('Error getting current position: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking location status: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();
      setState(() => _locationPermission = permission);
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission granted'),
            backgroundColor: Color(0xFF00695C),
          ),
        );
        _checkLocationStatus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Location Settings'),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _checkLocationStatus,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00695C),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF00695C),
              onRefresh: _checkLocationStatus,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Why we need location
                  _buildInfoCard(
                    isDarkMode: isDarkMode,
                    icon: Icons.info_outline_rounded,
                    title: 'Why Location is Needed',
                    description: 'Bottleji uses your location to:\n'
                        '• Show nearby recycling drops\n'
                        '• Calculate distances to drops\n'
                        '• Navigate to collection points\n'
                        '• Verify drop-off locations',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  // Location Service Status
                  _buildStatusCard(
                    isDarkMode: isDarkMode,
                    icon: _isLocationServiceEnabled ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                    title: 'Location Services',
                    status: _isLocationServiceEnabled ? 'Enabled' : 'Disabled',
                    isEnabled: _isLocationServiceEnabled,
                    description: _isLocationServiceEnabled
                        ? 'GPS is turned on'
                        : 'GPS is turned off on your device',
                    actionLabel: _isLocationServiceEnabled ? null : 'Open Settings',
                    onActionTap: _isLocationServiceEnabled ? null : _openLocationSettings,
                  ),
                  const SizedBox(height: 12),

                  // Permission Status
                  _buildStatusCard(
                    isDarkMode: isDarkMode,
                    icon: _getPermissionIcon(),
                    title: 'App Permission',
                    status: _getPermissionStatus(),
                    isEnabled: _locationPermission == LocationPermission.always || 
                               _locationPermission == LocationPermission.whileInUse,
                    description: _getPermissionDescription(),
                    actionLabel: _getPermissionActionLabel(),
                    onActionTap: _getPermissionAction(),
                  ),
                  const SizedBox(height: 12),

                  // Current Location
                  if (_currentPosition != null)
                    _buildLocationCard(
                      isDarkMode: isDarkMode,
                      position: _currentPosition!,
                    ),
                  
                  if (_currentPosition != null)
                    const SizedBox(height: 16),

                  // Permission explanation
                  if (_locationPermission == LocationPermission.denied ||
                      _locationPermission == LocationPermission.deniedForever)
                    _buildWarningCard(
                      isDarkMode: isDarkMode,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String status,
    required bool isEnabled,
    required String description,
    String? actionLabel,
    VoidCallback? onActionTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color(0xFF00695C).withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled ? const Color(0xFF00695C) : Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isEnabled ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isEnabled ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onActionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard({
    required bool isDarkMode,
    required Position position,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF00695C),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Current Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLocationDetail(
              isDarkMode: isDarkMode,
              label: 'Latitude',
              value: position.latitude.toStringAsFixed(6),
              icon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 8),
            _buildLocationDetail(
              isDarkMode: isDarkMode,
              label: 'Longitude',
              value: position.longitude.toStringAsFixed(6),
              icon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 8),
            _buildLocationDetail(
              isDarkMode: isDarkMode,
              label: 'Accuracy',
              value: '±${position.accuracy.toStringAsFixed(1)}m',
              icon: Icons.gps_fixed_rounded,
            ),
            const SizedBox(height: 8),
            _buildLocationDetail(
              isDarkMode: isDarkMode,
              label: 'Altitude',
              value: '${position.altitude.toStringAsFixed(1)}m',
              icon: Icons.terrain_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetail({
    required bool isDarkMode,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningCard({required bool isDarkMode}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location Access Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Without location permission, you won\'t be able to see nearby drops or use navigation features. Please enable location access to use the app fully.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPermissionIcon() {
    switch (_locationPermission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return Icons.check_circle_rounded;
      case LocationPermission.denied:
        return Icons.location_disabled_rounded;
      case LocationPermission.deniedForever:
        return Icons.block_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getPermissionStatus() {
    switch (_locationPermission) {
      case LocationPermission.always:
        return 'Always Allowed';
      case LocationPermission.whileInUse:
        return 'While Using App';
      case LocationPermission.denied:
        return 'Not Allowed';
      case LocationPermission.deniedForever:
        return 'Permanently Denied';
      default:
        return 'Unknown';
    }
  }

  String _getPermissionDescription() {
    switch (_locationPermission) {
      case LocationPermission.always:
        return 'The app can access location at any time, including in the background';
      case LocationPermission.whileInUse:
        return 'The app can access location only while you\'re using it';
      case LocationPermission.denied:
        return 'The app cannot access your location. Grant permission to use location features';
      case LocationPermission.deniedForever:
        return 'Location access has been permanently denied. You need to enable it in system settings';
      default:
        return 'Location permission status is unknown';
    }
  }

  String? _getPermissionActionLabel() {
    switch (_locationPermission) {
      case LocationPermission.denied:
        return 'Grant Permission';
      case LocationPermission.deniedForever:
        return 'Open App Settings';
      default:
        return null;
    }
  }

  VoidCallback? _getPermissionAction() {
    switch (_locationPermission) {
      case LocationPermission.denied:
        return _requestLocationPermission;
      case LocationPermission.deniedForever:
        return _openAppSettings;
      default:
        return null;
    }
  }
}

