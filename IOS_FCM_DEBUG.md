# iOS FCM Debugging Guide

## Where Logs Appear

**Logs appear in Flutter console (not backend logs):**

### How to View Flutter Logs:

1. **Run app with logs:**
   ```bash
   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
   flutter run
   ```

2. **Or use Xcode Console:**
   - Open Xcode
   - Window → Devices and Simulators
   - Select your device
   - Click "Open Console"
   - Filter for "FCM" or "APNS"

---

## Common Issues & Solutions

### Issue 1: No Logs Appearing

**Possible causes:**
1. App not running on physical device
2. FCM not initialized
3. Running in release mode (logs disabled)

**Solutions:**
- ✅ Run on **physical device** (simulator won't show APNs logs)
- ✅ Make sure you **grant notification permission** during onboarding
- ✅ Run in **debug mode**: `flutter run` (not release build)

---

### Issue 2: APNs Token is Null

**Look for this log:**
```
⚠️ FCMService: APNS token is null
```

**Possible causes:**
1. Running on simulator (APNs doesn't work on simulator)
2. APNs key not uploaded to Firebase
3. Bundle ID mismatch
4. App not properly signed

**Solutions:**
1. ✅ **Must run on physical device** (iPhone/iPad)
2. ✅ Verify APNs key uploaded to Firebase Console:
   - Go to: https://console.firebase.google.com/project/botleji/settings/cloudmessaging
   - Check "APNs Authentication Key" shows as configured
3. ✅ Verify Bundle ID matches:
   - Xcode: `com.example.botleji`
   - Firebase Console: `com.example.botleji`
4. ✅ Clean build:
   ```bash
   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
   flutter clean
   flutter pub get
   flutter run
   ```

---

### Issue 3: FCM Token is Null

**Look for this log:**
```
⚠️ FCMService: FCM token is null
```

**This happens when:**
- APNs token is null (see Issue 2 above)
- Firebase not properly configured

**Solution:**
- Fix APNs token issue first (Issue 2)

---

### Issue 4: Token Not Saved to Database

**Look for this log:**
```
🔔 FCMService: No auth token, skipping token save to backend
```

**Possible causes:**
1. User not logged in
2. Auth token expired
3. Backend endpoint not accessible

**Solutions:**
1. ✅ **Make sure you're logged in** to the app
2. ✅ Check if you have `auth_token` in SharedPreferences
3. ✅ Verify backend is running and accessible
4. ✅ After login, token should save automatically

**Note:** Token is saved:
- After FCM initialization (if logged in)
- After login (via `auth_provider.dart`)

---

## Step-by-Step Debug Process

### Step 1: Check You're on Physical Device

```bash
# List connected devices
flutter devices

# Should show your iPhone (not just simulators)
# Example output:
# iPhone 15 Pro (connected)
# iPhone 15 Pro Simulator (available)
```

**Run on physical device:**
```bash
flutter run -d <your-device-id>
```

---

### Step 2: Check Logs During App Launch

Run app and watch for these logs in order:

1. **Firebase Initialization:**
   ```
   Firebase initialized successfully
   FCM initialization deferred until after onboarding
   ```

2. **During Onboarding - Permission Request:**
   ```
   Requesting notification permission with FirebaseMessaging...
   FirebaseMessaging notification permission: AuthorizationStatus.authorized
   ✅ FCM service initialized after user granted notification permission
   ```

3. **FCM Initialization:**
   ```
   🔔 FCMService: Initializing Firebase Cloud Messaging...
   🔔 FCMService: Permission status: AuthorizationStatus.authorized
   🔔 FCMService: User granted permission
   ```

4. **APNs Token (iOS):**
   ```
   🔔 FCMService: iOS detected - getting APNS token first...
   🔔 FCMService: APNS Token: [long token]
   ```

5. **FCM Token:**
   ```
   🔔 FCMService: FCM Token: [long token]
   ```

6. **Token Save:**
   ```
   🔔 FCMService: Saving FCM token to backend...
   🔔 FCMService: FCM token saved to backend successfully
   ```

---

### Step 3: Verify APNs Configuration

1. **Firebase Console:**
   - Go to: https://console.firebase.google.com/project/botleji/settings/cloudmessaging
   - Check "APNs Authentication Key" shows:
     - ✅ Development: Configured
     - ✅ Production: Configured

2. **Xcode:**
   - Open `Runner.xcworkspace`
   - Select Runner target → Signing & Capabilities
   - Check:
     - ✅ Push Notifications capability added
     - ✅ Background Modes → Remote notifications checked
     - ✅ Team selected
     - ✅ Bundle ID: `com.example.botleji`

---

### Step 4: Verify User is Logged In

The token only saves if user is logged in!

**Check:**
1. Make sure you complete login after onboarding
2. Look for this log after login:
   ```
   ✅ FCM token saved to backend after login
   ```

**If you see this log:**
```
🔔 FCMService: No auth token, skipping token save to backend
```

**Solution:** Log in to the app first!

---

### Step 5: Check Database

**After successful token save, check MongoDB:**

```javascript
// In MongoDB, find your user:
db.users.findOne({ email: "your-email@example.com" })

// Should show:
{
  ...
  fcmToken: "your-fcm-token-here"
}
```

---

## Quick Test Checklist

- [ ] Running on **physical device** (not simulator)
- [ ] APNs key uploaded to Firebase (dev & prod)
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes → Remote notifications enabled
- [ ] App built and run after Xcode changes
- [ ] Notification permission granted during onboarding
- [ ] User logged in to app
- [ ] Check Flutter logs for FCM tokens
- [ ] Check database for fcmToken field

---

## Manual Token Test

If token generation works but saving doesn't, you can manually save:

1. **Get token from logs:**
   - Look for: `🔔 FCMService: FCM Token: [token]`
   - Copy the token

2. **Manually save via API:**
   ```bash
   curl -X POST https://bottleji-api.onrender.com/auth/fcm-token \
     -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"fcmToken": "YOUR_FCM_TOKEN"}'
   ```

---

## Still Not Working?

If you've checked everything and still no token:

1. **Rebuild app from scratch:**
   ```bash
   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
   flutter clean
   rm -rf ios/Pods ios/Podfile.lock
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

2. **Check Xcode build settings:**
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Build again

3. **Verify APNs key is correct:**
   - Re-download from Apple Developer Portal (if needed)
   - Re-upload to Firebase Console

4. **Check Firebase project settings:**
   - Make sure iOS app is added to Firebase project
   - Bundle ID matches exactly

---

## Expected Logs Sequence

When everything works correctly, you should see:

```
Firebase initialized successfully
FCM initialization deferred until after onboarding
Requesting notification permission with FirebaseMessaging...
FirebaseMessaging notification permission: AuthorizationStatus.authorized (granted: true)
✅ FCM service initialized after user granted notification permission
🔔 FCMService: Initializing Firebase Cloud Messaging...
🔔 FCMService: Permission status: AuthorizationStatus.authorized
🔔 FCMService: User granted permission
🔔 FCMService: iOS detected - getting APNS token first...
🔔 FCMService: APNS Token: [64-char hex string]
🔔 FCMService: FCM Token: [long token string]
🔔 FCMService: Saving FCM token to backend...
🔔 FCMService: FCM token saved to backend successfully
```

If you see different logs or errors, use this guide to debug!

