import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:botleji/core/services/network_initialization_service.dart';
import 'package:botleji/core/config/server_config.dart';
import 'package:botleji/features/notifications/data/services/notification_service.dart';
import 'package:botleji/l10n/app_localizations.dart';
// TODO: FCM is not yet implemented
// import 'package:botleji/core/services/fcm_service.dart';

const appGreenColor = Color(0xFF00695C);

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  Map<Permission, bool> _permissionStatuses = {};
  bool _isLoading = false;

  List<PermissionItem> _getPermissions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      PermissionItem(
        permission: Permission.location,
        title: l10n.locationServices,
        description: l10n.accessLocationToShowNearbyDrops,
        icon: Icons.location_on,
        isRequired: true,
      ),
      PermissionItem(
        permission: Permission.bluetooth, // placeholder; not used for iOS local network
        title: l10n.localNetworkAccess,
        description: l10n.allowAppToDiscoverServicesOnWifi,
        icon: Icons.wifi,
        isRequired: true,
        isLocalNetwork: true,
      ),
      PermissionItem(
        permission: Permission.notification,
        title: l10n.notifications,
        description: l10n.receiveRealTimeUpdatesAboutDrops,
        icon: Icons.notifications,
        isRequired: true,
      ),
      PermissionItem(
        permission: Permission.storage,
        title: l10n.photoStorage,
        description: l10n.saveAndAccessPhotosOfRecyclableItems,
        icon: Icons.photo_library,
        isRequired: false,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPermissionStatuses();
  }

  Future<void> _checkPermissionStatuses() async {
    if (!mounted) return;
    final permissions = _getPermissions(context);
    final statuses = <Permission, bool>{};
    for (final permission in permissions) {
      bool isGranted = false;
      final item = permission;
      
      // Check permissions using the same packages used elsewhere in the app
      if (item.isLocalNetwork) {
        final prefs = await SharedPreferences.getInstance();
        isGranted = prefs.getBool('local_network_granted') ?? false;
        print('Initial check - ${item.title}: granted flag = $isGranted');
      } else if (permission.permission == Permission.location) {
        // Use Geolocator (same as home screen and map screens)
        final locationPermission = await Geolocator.checkPermission();
        isGranted = locationPermission == LocationPermission.whileInUse || 
                   locationPermission == LocationPermission.always;
        print('Initial check - ${item.title}: $locationPermission (granted: $isGranted)');
      } else if (permission.permission == Permission.notification) {
        // Use FirebaseMessaging (same as notification settings screen)
        try {
          final messaging = FirebaseMessaging.instance;
          final settings = await messaging.getNotificationSettings();
          isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                     settings.authorizationStatus == AuthorizationStatus.provisional;
          print('Initial check - ${item.title}: ${settings.authorizationStatus} (granted: $isGranted)');
        } catch (e) {
          isGranted = false;
          print('Initial check - ${item.title}: Error checking permission: $e');
        }
      } else if (permission.permission == Permission.storage) {
        // Photo Storage permission - treat as granted by default (ImagePicker handles it when needed)
        isGranted = true;
        print('Initial check - ${item.title}: Granted by default (handled by ImagePicker)');
      } else {
        // Handle other permissions with permission_handler
        final status = await permission.permission.status;
        isGranted = status.isGranted;
        print('Initial check - ${item.title}: $status');
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
      if (permissionItem.isLocalNetwork) {
        print('Requesting local network permission via network init...');
        try {
          // 1) Proactively touch LAN to trigger iOS "Local Network" prompt
          // Try a few common gateway IPs with very short timeouts
          final candidates = <String>['192.168.1.1', '192.168.0.1', '10.0.0.1', '172.20.10.1'];
          for (final ip in candidates) {
            try {
              print('Attempting LAN connect to $ip:80 to trigger prompt...');
              final socket = await Socket.connect(ip, 80, timeout: const Duration(milliseconds: 400));
              socket.destroy();
              print('Connected to $ip:80 (prompt should have appeared)');
              break;
            } catch (_) {
              // Ignore; the attempt itself is enough to trigger the prompt if needed
            }
          }
          
          // 2) Run our normal network init (will still use tunnel until we flip the flag below)
          await NetworkInitializationService.initialize();
          final detectedApiUrl = NetworkInitializationService.apiUrl ?? ServerConfig.apiBaseUrlSync;
          NotificationService.initialize(detectedApiUrl);
          
          // 3) Persist and flip runtime flag so future connections may use LAN
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('local_network_granted', true);
          // Inform ServerConfig for sync URL selection going forward
          ServerConfig.setLocalNetworkGranted(true);
          // Clear any cached IP so future auto-detection (if enabled) can re-run
          ServerConfig.clearIpCache();
          isGranted = true;
          print('Local network initialization completed, marking as granted');
        } catch (e) {
          print('Local network init error: $e');
          isGranted = false;
        }
        
      } else if (permissionItem.permission == Permission.location) {
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
          
          // TODO: Initialize FCM service after user grants notification permission
          // FCM is not yet implemented, so commenting out for now
          // if (isGranted) {
          //   try {
          //     await FCMService().initialize();
          //     print('✅ FCM service initialized after user granted notification permission');
          //   } catch (e) {
          //     print('⚠️ Error initializing FCM service: $e');
          //     // Don't fail the permission request if FCM init fails
          //   }
          // }
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
      backgroundColor: Theme.of(context).colorScheme.background,
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
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).appPermissions,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
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
                    Text(
                      AppLocalizations.of(context).bottlejiRequiresAdditionalPermissions,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).permissionsHelpProvideBestExperience,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Permissions list
              Expanded(
                child: Builder(
                  builder: (context) {
                    final permissions = _getPermissions(context);
                    return ListView.builder(
                      itemCount: permissions.length,
                      itemBuilder: (context, index) {
                        final permission = permissions[index];
                    final isGranted = _permissionStatuses[permission.permission] ?? false;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              permission.icon,
                              color: isGranted ? appGreenColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  permission.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                child: Text(
                                  AppLocalizations.of(context).enable,
                                  style: const TextStyle(
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
                    _canContinueToApp 
                        ? AppLocalizations.of(context).continueToApp 
                        : AppLocalizations.of(context).enableRequiredPermissions,
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
  final bool isLocalNetwork;

  PermissionItem({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    required this.isRequired,
    this.isLocalNetwork = false,
  });
}
