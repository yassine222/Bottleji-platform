import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const appGreenColor = Color(0xFF00695C);

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  Map<Permission, bool> _permissionStatuses = {};
  bool _isLoading = false;

  final List<PermissionItem> _permissions = [
    PermissionItem(
      permission: Permission.location,
      title: 'Location Services',
      description: 'Access your location to show nearby drops and enable navigation for collectors.',
      icon: Icons.location_on,
      isRequired: true,
    ),
    PermissionItem(
      permission: Permission.notification,
      title: 'Notifications',
      description: 'Receive real-time updates about your drops, collections, and important announcements.',
      icon: Icons.notifications,
      isRequired: true,
    ),
    PermissionItem(
      permission: Permission.storage,
      title: 'Photo Storage',
      description: 'Save and access photos of your recyclable items.',
      icon: Icons.photo_library,
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissionStatuses();
  }

  Future<void> _checkPermissionStatuses() async {
    final statuses = <Permission, bool>{};
    for (final permission in _permissions) {
      bool isGranted = false;
      
      // Check permissions using the same packages used elsewhere in the app
      if (permission.permission == Permission.location) {
        // Use Geolocator (same as home screen and map screens)
        final locationPermission = await Geolocator.checkPermission();
        isGranted = locationPermission == LocationPermission.whileInUse || 
                   locationPermission == LocationPermission.always;
        print('Initial check - ${permission.title}: $locationPermission (granted: $isGranted)');
      } else if (permission.permission == Permission.notification) {
        // Use FirebaseMessaging (same as notification settings screen)
        try {
          final messaging = FirebaseMessaging.instance;
          final settings = await messaging.getNotificationSettings();
          isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                     settings.authorizationStatus == AuthorizationStatus.provisional;
          print('Initial check - ${permission.title}: ${settings.authorizationStatus} (granted: $isGranted)');
        } catch (e) {
          isGranted = false;
          print('Initial check - ${permission.title}: Error checking permission: $e');
        }
      } else if (permission.permission == Permission.storage) {
        // Photo Storage permission - treat as granted by default (ImagePicker handles it when needed)
        isGranted = true;
        print('Initial check - ${permission.title}: Granted by default (handled by ImagePicker)');
      } else {
        // Handle other permissions with permission_handler
        final status = await permission.permission.status;
        isGranted = status.isGranted;
        print('Initial check - ${permission.title}: $status');
      }
      
      statuses[permission.permission] = isGranted;
    }
    
    if (mounted) {
      setState(() {
        _permissionStatuses = statuses;
      });
    }
  }

  Future<void> _requestPermission(PermissionItem permissionItem) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool isGranted = false;
      
      // Handle permissions with the same packages used elsewhere in the app
      if (permissionItem.permission == Permission.location) {
        // Use Geolocator (same as home screen and map screens)
        print('Requesting location permission with Geolocator...');
        
        LocationPermission currentPermission = await Geolocator.checkPermission();
        print('Current location permission: $currentPermission');
        
        if (currentPermission == LocationPermission.denied) {
          currentPermission = await Geolocator.requestPermission();
          print('Requested location permission: $currentPermission');
        }
        
        if (currentPermission == LocationPermission.deniedForever) {
          print('Location permission permanently denied, opening app settings');
          await Geolocator.openAppSettings();
          currentPermission = await Geolocator.checkPermission();
        }
        
        isGranted = currentPermission == LocationPermission.whileInUse || 
                   currentPermission == LocationPermission.always;
        
        print('Final location permission: $currentPermission (granted: $isGranted)');
        
      } else if (permissionItem.permission == Permission.notification) {
        // Use FirebaseMessaging (same as notification settings screen)
        print('Requesting notification permission with FirebaseMessaging...');
        
        try {
          final messaging = FirebaseMessaging.instance;
          final status = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          
          isGranted = status.authorizationStatus == AuthorizationStatus.authorized ||
                     status.authorizationStatus == AuthorizationStatus.provisional;
          
          print('FirebaseMessaging notification permission: ${status.authorizationStatus} (granted: $isGranted)');
        } catch (e) {
          print('Error requesting notification permission: $e');
          isGranted = false;
        }
        
      } else if (permissionItem.permission == Permission.storage) {
        // Photo Storage permission - always granted (ImagePicker handles it when needed)
        isGranted = true;
        print('Photo Storage permission: Always granted (handled by ImagePicker)');
      } else {
        // Handle other permissions with permission_handler
        final currentStatus = await permissionItem.permission.status;
        print('Current status for ${permissionItem.title}: $currentStatus');
        
        PermissionStatus status;
        
        if (currentStatus == PermissionStatus.permanentlyDenied) {
          print('Permission permanently denied, opening app settings');
          await openAppSettings();
          status = await permissionItem.permission.status;
        } else if (currentStatus == PermissionStatus.denied) {
          print('Permission denied, requesting again');
          status = await permissionItem.permission.request();
        } else {
          status = await permissionItem.permission.request();
        }
        
        print('Final status for ${permissionItem.title}: $status');
        isGranted = status.isGranted;
      }
      
      print('Permission ${permissionItem.title}: ${isGranted ? "Granted" : "Denied"}');
      
      setState(() {
        _permissionStatuses[permissionItem.permission] = isGranted;
      });

    } catch (e) {
      print('Error requesting permission: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _continueToApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/main');
  }

  bool get _canContinueToApp {
    // Enable continue button when location and notifications are granted
    final locationGranted = _permissionStatuses[Permission.location] ?? false;
    final notificationsGranted = _permissionStatuses[Permission.notification] ?? false;
    
    return locationGranted && notificationsGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/onboarding'),
                    icon: const Icon(Icons.arrow_back, color: appGreenColor),
                  ),
                  const Expanded(
                    child: Text(
                      'App Permissions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Warning icon and description
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 40,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bottleji requires additional permissions to work properly',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These permissions help us provide you with the best experience.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Permissions list
              Expanded(
                child: ListView.builder(
                  itemCount: _permissions.length,
                  itemBuilder: (context, index) {
                    final permission = _permissions[index];
                    final isGranted = _permissionStatuses[permission.permission] ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isGranted 
                                  ? appGreenColor.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              permission.icon,
                              color: isGranted ? appGreenColor : Colors.grey,
                              size: 24,
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Content
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  permission.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  permission.description,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Status/Action
                          if (isGranted)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: appGreenColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          else
                            SizedBox(
                              width: 60,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _requestPermission(permission),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreenColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Enable',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_canContinueToApp) ? null : _continueToApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canContinueToApp ? appGreenColor : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _canContinueToApp ? 'Continue to App' : 'Enable Required Permissions',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionItem {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final bool isRequired;

  PermissionItem({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    required this.isRequired,
  });
}
