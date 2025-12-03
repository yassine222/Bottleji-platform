# Android FCM Push Notifications Setup Guide

This guide will help you configure Firebase Cloud Messaging (FCM) for Android push notifications in your Bottleji app.

## Prerequisites

✅ **Already Configured:**
- Firebase project created (`botleji`)
- `google-services.json` file exists in `android/app/`
- Google Services plugin configured in `build.gradle.kts`
- FCM service code implemented
- Backend FCM endpoint exists (`/auth/fcm-token`)

## Step 1: Verify Firebase Configuration

### 1.1 Check `google-services.json`

Verify that `android/app/google-services.json` exists and contains your Android app configuration:

```bash
cat botleji/android/app/google-services.json
```

You should see:
- `project_id`: "botleji"
- `package_name`: "com.example.botleji"
- `mobilesdk_app_id`: Your app ID

### 1.2 Verify Google Services Plugin

Check that `android/app/build.gradle.kts` includes:

```kotlin
plugins {
    id("com.google.gms.google-services")
    // ... other plugins
}
```

✅ **Already configured!**

---

## Step 2: Verify Android Manifest

### 2.1 Check Permissions

Verify `android/app/src/main/AndroidManifest.xml` includes:

```xml
<!-- Notification Permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

✅ **Already configured!**

### 2.2 Verify Application Configuration

The manifest should have:
- `android:name="${applicationName}"` in `<application>` tag
- MainActivity with `android:launchMode="singleTop"`

✅ **Already configured!**

---

## Step 3: Enable FCM Integration in Code

### 3.1 Enable FCM Token Saving After Login

The FCM token saving is currently commented out. We need to enable it:

**File:** `botleji/lib/features/auth/presentation/providers/auth_provider.dart`

**Current code (commented):**
```dart
// TODO: Save FCM token to backend after login
// FCM is not yet implemented, so commenting out for now
// try {
//   final fcmService = FCMService();
//   await fcmService.saveTokenToBackend();
//   AppLogger.log('✅ FCM token saved to backend after login');
// } catch (e) {
//   AppLogger.log('❌ Error saving FCM token after login: $e');
//   // Don't fail login if FCM token save fails
// }
```

**Action:** Uncomment and enable this code (will be done in next step)

### 3.2 Ensure FCM Initialization After Permissions

**File:** `botleji/lib/features/onboarding/presentation/screens/permissions_screen.dart`

Verify that FCM is initialized after user grants notification permission. The code should call:

```dart
await FCMService().initialize();
```

**Status:** Currently commented out - needs to be enabled

---

## Step 4: Test FCM Configuration

### 4.1 Build and Run on Android Device

```bash
cd botleji
flutter clean
flutter pub get
flutter run
```

### 4.2 Check Logs for FCM Token

After running the app and completing onboarding:

Look for these logs:
```
🔔 FCMService: Initializing Firebase Cloud Messaging...
🔔 FCMService: Permission status: AuthorizationStatus.authorized
🔔 FCMService: FCM Token: [long token string]
🔔 FCMService: FCM token saved to backend successfully
```

### 4.3 Verify Token in Backend

1. Check your MongoDB database
2. Find a user document
3. Verify that `fcmToken` field is populated

Or check backend logs for:
```
FCM token saved for user [userId]
```

---

## Step 5: Test Push Notification

### 5.1 Get FCM Token from Logs

Copy the FCM token from the app logs (look for `🔔 FCMService: FCM Token: ...`)

### 5.2 Send Test Notification via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **botleji**
3. Navigate to **Cloud Messaging**
4. Click **"Send your first message"** or **"New notification"**
5. Enter:
   - **Notification title**: "Test Notification"
   - **Notification text**: "This is a test from Firebase"
6. Click **"Next"**
7. Select **"Send test message"**
8. Paste your FCM token
9. Click **"Test"**

### 5.3 Expected Result

You should receive a notification on your Android device! 🎉

---

## Step 6: Test Notification Scenarios

### 6.1 Foreground Notifications

When the app is open:
- Notification should appear as a local notification
- Check logs: `🔔 FCMService: Foreground message received`

### 6.2 Background Notifications

When the app is in background:
- Notification should appear in the notification tray
- Tapping it should open the app

### 6.3 Terminated App Notifications

When the app is closed:
- Notification should appear in the notification tray
- Tapping it should open the app
- Check logs: `🔔 FCMService: App opened from terminated state via notification`

---

## Troubleshooting

### Issue: FCM Token is null

**Possible causes:**
1. Firebase not initialized properly
2. `google-services.json` missing or incorrect
3. App not connected to internet

**Solutions:**
- Verify `google-services.json` is in `android/app/`
- Check Firebase initialization logs
- Ensure device has internet connection
- Try `flutter clean` and rebuild

### Issue: Token not saving to backend

**Possible causes:**
1. User not logged in (no auth token)
2. Backend endpoint not accessible
3. Network error

**Solutions:**
- Ensure user is logged in before FCM initialization
- Check backend logs for errors
- Verify `/auth/fcm-token` endpoint is working
- Check API base URL configuration

### Issue: Notifications not received

**Possible causes:**
1. Notification permission not granted
2. FCM token not saved to backend
3. Backend not sending notifications
4. Device in Do Not Disturb mode

**Solutions:**
- Check notification permissions in app settings
- Verify FCM token exists in database
- Check backend FCM service logs
- Disable Do Not Disturb mode
- Try sending test notification from Firebase Console

### Issue: "Invalid registration token" error

**Possible causes:**
1. Token expired (should auto-refresh)
2. App reinstalled (old token invalid)
3. Token format incorrect

**Solutions:**
- App should automatically refresh token
- Re-initialize FCM after app reinstall
- Check token format in logs

---

## Next Steps

Once Android FCM is working:

1. ✅ Test all notification scenarios (foreground, background, terminated)
2. ✅ Verify token refresh works (uninstall/reinstall app)
3. ✅ Test backend notification sending
4. ⏳ Wait for Apple Developer Program approval
5. ⏳ Configure iOS APNs (see `FCM_SETUP_GUIDE.md`)

---

## Quick Reference

### Important Files
- **Flutter FCM Service:** `botleji/lib/core/services/fcm_service.dart`
- **Backend FCM Service:** `backend/src/modules/notifications/fcm.service.ts`
- **Backend Auth Controller:** `backend/src/modules/auth/auth.controller.ts`
- **Android Config:** `botleji/android/app/google-services.json`
- **Android Manifest:** `botleji/android/app/src/main/AndroidManifest.xml`

### Firebase Console Links
- **Project Settings:** https://console.firebase.google.com/project/botleji/settings/general
- **Cloud Messaging:** https://console.firebase.google.com/project/botleji/settings/cloudmessaging
- **Service Accounts:** https://console.firebase.google.com/project/botleji/settings/serviceaccounts/adminsdk

### Test Commands
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# Check logs for FCM
flutter logs | grep FCM
```

---

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Check backend logs for FCM service errors
3. Check Flutter app logs for FCM token generation
4. Verify all configuration steps were completed
5. Test with Firebase Console test message first

