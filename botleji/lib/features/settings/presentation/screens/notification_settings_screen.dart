import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = true;
  AuthorizationStatus? _notificationPermission;
  
  // Notification preferences
  bool _generalNotifications = true;
  bool _dropNotifications = true;
  bool _collectionNotifications = true;
  bool _messageNotifications = true;
  bool _supportNotifications = true;
  bool _promotionalNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Check notification permission using Firebase Messaging
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      _notificationPermission = settings.authorizationStatus;
      
      debugPrint('🔔 Notification permission status: ${_notificationPermission}');
      
      // Load preferences from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _generalNotifications = prefs.getBool('general_notifications') ?? true;
      _dropNotifications = prefs.getBool('drop_notifications') ?? true;
      _collectionNotifications = prefs.getBool('collection_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _supportNotifications = prefs.getBool('support_notifications') ?? true;
      _promotionalNotifications = prefs.getBool('promotional_notifications') ?? false;
      _soundEnabled = prefs.getBool('notification_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
      
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('Error saving preference: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final status = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      setState(() => _notificationPermission = status.authorizationStatus);
      
      if (status.authorizationStatus == AuthorizationStatus.authorized ||
          status.authorizationStatus == AuthorizationStatus.provisional) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission granted'),
            backgroundColor: Color(0xFF00695C),
          ),
        );
      } else if (status.authorizationStatus == AuthorizationStatus.denied) {
        _showOpenSettingsDialog();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<void> _openAppSettings() async {
    // On iOS, we can't directly open app settings, so show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open Settings'),
        content: const Text(
          'To enable notifications, please:\n\n'
          '1. Go to your device Settings\n'
          '2. Find Bottleji app\n'
          '3. Tap Notifications\n'
          '4. Enable Allow Notifications',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Notification permission has been permanently denied. '
          'Please enable it in app settings to receive notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00695C),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
              ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                _buildInfoCard(isDarkMode: isDarkMode),
                const SizedBox(height: 16),

                // Permission Status Card
                _buildPermissionCard(isDarkMode: isDarkMode),
                const SizedBox(height: 16),

                // General Notifications Toggle
                _buildSectionHeader(isDarkMode: isDarkMode, title: 'Notification Types'),
                const SizedBox(height: 12),
                
                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.notifications_active_rounded,
                  title: 'General Notifications',
                  subtitle: 'Enable all notifications',
                  value: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _generalNotifications = value);
                    await _savePreference('general_notifications', value);
                    
                    // If turning off general, turn off all others
                    if (!value) {
                      setState(() {
                        _dropNotifications = false;
                        _collectionNotifications = false;
                        _messageNotifications = false;
                        _supportNotifications = false;
                        _promotionalNotifications = false;
                      });
                      await _savePreference('drop_notifications', false);
                      await _savePreference('collection_notifications', false);
                      await _savePreference('message_notifications', false);
                      await _savePreference('support_notifications', false);
                      await _savePreference('promotional_notifications', false);
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Drop Notifications
                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.local_drink_rounded,
                  title: 'Drop Notifications',
                  subtitle: 'New drops nearby, status updates',
                  value: _dropNotifications,
                  enabled: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _dropNotifications = value);
                    await _savePreference('drop_notifications', value);
                  },
                ),
                const SizedBox(height: 8),

                // Collection Notifications
                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.recycling_rounded,
                  title: 'Collection Notifications',
                  subtitle: 'Collection accepted, completed, cancelled',
                  value: _collectionNotifications,
                  enabled: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _collectionNotifications = value);
                    await _savePreference('collection_notifications', value);
                  },
                ),
                const SizedBox(height: 8),

                // Message Notifications
                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.message_rounded,
                  title: 'Message Notifications',
                  subtitle: 'New messages from support or users',
                  value: _messageNotifications,
                  enabled: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _messageNotifications = value);
                    await _savePreference('message_notifications', value);
                  },
                ),
                const SizedBox(height: 8),

                // Support Notifications
                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.support_agent_rounded,
                  title: 'Support Notifications',
                  subtitle: 'Ticket updates, admin replies',
                  value: _supportNotifications,
                  enabled: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _supportNotifications = value);
                    await _savePreference('support_notifications', value);
                  },
                ),
                const SizedBox(height: 8),

                // Promotional Notifications
                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.card_giftcard_rounded,
                  title: 'Promotional Notifications',
                  subtitle: 'Offers, rewards, and updates',
                  value: _promotionalNotifications,
                  enabled: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _promotionalNotifications = value);
                    await _savePreference('promotional_notifications', value);
                  },
                ),

                const SizedBox(height: 24),

                // Notification Behavior
                _buildSectionHeader(isDarkMode: isDarkMode, title: 'Notification Behavior'),
                const SizedBox(height: 12),

                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.volume_up_rounded,
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  enabled: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _soundEnabled = value);
                    await _savePreference('notification_sound', value);
                  },
                ),
                const SizedBox(height: 8),

                _buildNotificationToggle(
                  isDarkMode: isDarkMode,
                  icon: Icons.vibration_rounded,
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: _vibrationEnabled,
                  enabled: _generalNotifications,
                  onChanged: (value) async {
                    setState(() => _vibrationEnabled = value);
                    await _savePreference('notification_vibration', value);
                    
                    // Trigger haptic feedback when vibration is turned ON
                    if (value) {
                      HapticFeedback.mediumImpact();
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildInfoCard({required bool isDarkMode}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay Updated',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customize which notifications you want to receive. You can always change these settings later.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildPermissionCard({required bool isDarkMode}) {
    final colorScheme = Theme.of(context).colorScheme;
    debugPrint('🔔 Building permission card with status: $_notificationPermission');
    final isGranted = _notificationPermission == AuthorizationStatus.authorized ||
                      _notificationPermission == AuthorizationStatus.provisional;
    final isDenied = _notificationPermission == AuthorizationStatus.denied;
    debugPrint('🔔 isGranted: $isGranted, isDenied: $isDenied');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
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
                    color: isGranted
                        ? colorScheme.primary.withOpacity(0.1)
                        : colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isGranted ? Icons.check_circle_rounded : Icons.notifications_off_rounded,
                    color: isGranted ? colorScheme.primary : colorScheme.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notification Permission',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isGranted ? colorScheme.primary : colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isGranted ? 'Enabled' : 'Disabled',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isGranted ? colorScheme.primary : colorScheme.error,
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
              isGranted
                  ? 'The app can send you notifications'
                  : 'Notification permission is required to receive updates',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            if (!isGranted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isDenied ? _openAppSettings : _requestNotificationPermission,
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
                    isDenied ? 'How to Enable' : 'Enable Notifications',
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

  Widget _buildSectionHeader({required bool isDarkMode, required String title}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required bool isDarkMode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        enabled: enabled,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: enabled
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.outline.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: enabled
                ? colorScheme.onSurface.withOpacity(0.7)
                : colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: colorScheme.primary,
        ),
      ),
    );
  }
}

