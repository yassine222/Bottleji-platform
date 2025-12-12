# Firebase Phone Auth iOS Setup Checklist

## ✅ Completed Steps

### 1. **Before You Begin**
- ✅ App connected to Firebase project
- ✅ Firebase dependencies installed via CocoaPods (`firebase_auth` package)
- ✅ `-ObjC` flag added (handled by CocoaPods)

### 2. **Enable Phone Number Sign-in**
- ⚠️ **ACTION REQUIRED:** Enable Phone Number sign-in in Firebase Console
  1. Go to [Firebase Console](https://console.firebase.google.com)
  2. Select your project: **botleji**
  3. Navigate to **Authentication** → **Sign-in method**
  4. Click on **"Phone"** provider
  5. Toggle **"Enable"** to ON
  6. Click **"Save"**

### 3. **Enable App Verification**

#### 3.1 Silent APNs Notifications ✅
- ✅ Push notifications enabled in Xcode
- ✅ APNs authentication key (`.p8`) uploaded to Firebase Console
- ✅ Background Modes enabled with **"Remote notifications"** checked
- ✅ APNs device token registration implemented in `AppDelegate.swift`
- ✅ Push notification handling for Firebase Auth implemented

#### 3.2 reCAPTCHA Verification ✅
- ✅ Custom URL scheme added to `Info.plist`:
  - Scheme: `app-1-414913880297-ios-4621c0674928dcfb8a9078` (Encoded App ID)
- ✅ URL scheme handling implemented in `AppDelegate.swift` for reCAPTCHA redirects

### 4. **Manual APNs Handling** ✅
Since `FirebaseAppDelegateProxyEnabled` is set to `false` in `Info.plist`, we've manually implemented:

- ✅ **APNs Device Token Registration:**
  ```swift
  override func application(_ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  ```

- ✅ **Push Notification Handling:**
  ```swift
  override func application(_ application: UIApplication,
    didReceiveRemoteNotification notification: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if Auth.auth().canHandleNotification(notification) {
      completionHandler(.noData)
      return
    }
    super.application(application, didReceiveRemoteNotification: notification, fetchCompletionHandler: completionHandler)
  }
  ```

- ✅ **Custom URL Scheme Handling:**
  ```swift
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }
    // ... other URL handling
  }
  ```

### 5. **Flutter Implementation** ✅
- ✅ `PhoneVerificationService` uses Firebase Phone Auth
- ✅ Debug mode disabled (no hardcoded OTPs)
- ✅ Backend verifies Firebase tokens using Firebase Admin SDK
- ✅ Phone number extracted from verified token

## ⚠️ Action Required

### 1. Enable Phone Number Sign-in in Firebase Console
**This is the only remaining step you need to do manually:**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **botleji**
3. Navigate to **Authentication** → **Sign-in method**
4. Find **"Phone"** in the list
5. Click on it
6. Toggle **"Enable"** to ON
7. (Optional) Set SMS region policy if needed
8. Click **"Save"**

### 2. Test Phone Authentication
After enabling Phone sign-in in Firebase Console:

1. **Test on Physical Device** (simulator won't work for silent push notifications)
2. **Test with Background App Refresh:**
   - **Enabled:** Should use silent APNs (no reCAPTCHA)
   - **Disabled:** Should fall back to reCAPTCHA
3. **Test on Simulator:** Will always use reCAPTCHA (this is expected)

## How It Works

### Primary Flow (Silent APNs)
1. User enters phone number
2. App calls `verifyPhoneNumber()`
3. Firebase sends **silent push notification** to device
4. App receives notification → Firebase verifies app
5. Firebase sends SMS with OTP code
6. User enters OTP
7. App verifies with Firebase → Gets Firebase ID token
8. App sends token to backend
9. Backend verifies token → Creates/authenticates user

### Fallback Flow (reCAPTCHA)
1. User enters phone number
2. App calls `verifyPhoneNumber()`
3. Silent push notification fails (e.g., background refresh disabled)
4. Firebase shows **reCAPTCHA challenge** in `SFSafariViewController`
5. User completes reCAPTCHA
6. Firebase sends SMS with OTP code
7. User enters OTP
8. App verifies with Firebase → Gets Firebase ID token
9. App sends token to backend
10. Backend verifies token → Creates/authenticates user

## Configuration Files

### `Info.plist`
- ✅ `CFBundleURLTypes` with Encoded App ID: `app-1-414913880297-ios-4621c0674928dcfb8a9078`
- ✅ `FirebaseAppDelegateProxyEnabled` = `false` (manual handling)
- ✅ `UIBackgroundModes` includes `remote-notification`

### `AppDelegate.swift`
- ✅ `setAPNSToken()` - Passes APNs token to Firebase Auth
- ✅ `canHandleNotification()` - Handles Firebase Auth push notifications
- ✅ `canHandleURL()` - Handles reCAPTCHA redirect URLs

## Notes

- **Silent push notifications** don't require user permission (iOS 8.0+)
- **reCAPTCHA** is only shown when silent push fails
- **Physical device required** for testing silent push notifications
- **Simulator** will always use reCAPTCHA (this is normal)
- **Background App Refresh** must be enabled for silent push to work

## Troubleshooting

### Issue: "reCAPTCHA verification failed"
- Check that custom URL scheme is correctly set in `Info.plist`
- Verify Encoded App ID matches Firebase Console
- Ensure `canHandleURL()` is implemented in `AppDelegate`

### Issue: "Silent push notification not received"
- Ensure app is running on **physical device** (not simulator)
- Check that **Background App Refresh** is enabled
- Verify APNs key is uploaded to Firebase Console
- Check that `setAPNSToken()` is called in `AppDelegate`

### Issue: "Phone number sign-in not enabled"
- Go to Firebase Console → Authentication → Sign-in method
- Enable "Phone" provider

