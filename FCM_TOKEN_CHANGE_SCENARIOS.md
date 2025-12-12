# When FCM Token Changes - Complete List

## Overview

The FCM token is designed to be **relatively stable** - it doesn't change frequently. However, there are several scenarios where it can change.

---

## Scenarios Where FCM Token Changes

### 1. ✅ App Reinstallation (You Already Know This)
- When user uninstalls and reinstalls the app
- New app instance = new FCM token

---

### 2. 🔄 Token Refresh by Firebase
**Most Common After Reinstallation:**
- Firebase automatically refreshes tokens periodically
- Usually happens after **long periods of inactivity** (weeks/months)
- Token rotation for security reasons
- Your code automatically handles this with `onTokenRefresh` listener

**How to detect:**
- `FirebaseMessaging.onTokenRefresh` event fires
- New token is automatically saved to backend (if your code handles it)

---

### 3. 🧹 App Data Cleared
**Android:**
- Settings → Apps → Your App → Storage → Clear Data
- Settings → Apps → Your App → Storage → Clear Cache (sometimes)
- Factory Reset

**iOS:**
- Settings → General → iPhone Storage → Your App → Offload App
- Settings → General → Reset → Erase All Content and Settings

**Result:** App behaves like a fresh install, generates new FCM token

---

### 4. 🔐 Firebase Project Reset
- If Firebase project settings are changed significantly
- If Firebase project is deleted and recreated
- If Firebase App is deleted and recreated in Firebase Console

**Result:** All FCM tokens become invalid, new tokens are generated

---

### 5. 📱 Device Factory Reset
- User performs factory reset on their device
- All apps are reinstalled
- New FCM tokens generated for all apps

---

### 6. 🔄 Firebase SDK Update
**Rare, but possible:**
- If Firebase SDK has a major version update
- If Firebase changes token generation algorithm
- Usually backward compatible, but sometimes tokens refresh

---

### 7. 🗑️ Manual Token Deletion
**If you call:**
```dart
await FirebaseMessaging.instance.deleteToken();
```
**Result:** Token is deleted, next call to `getToken()` generates a new one

---

### 8. 🔄 App Update (Sometimes)
**Rare cases:**
- Major app version updates (especially if app ID changes)
- Android: App signing key changes
- iOS: Bundle ID changes

**Note:** Normal app updates usually **DON'T** change the token

---

### 9. 📶 Network/Device Changes (Extremely Rare)
**Very rare scenarios:**
- Device MAC address changes
- Significant device hardware changes
- Firebase detecting suspicious activity (security measure)

---

### 10. 🔧 Firebase Admin SDK Reset
**If on backend:**
- Firebase Admin SDK is reinitialized incorrectly
- Service account changes
- Project ID changes

**Result:** Backend can't validate old tokens, but tokens themselves might not change

---

## When Token DOESN'T Change

✅ **Normal app updates** (version updates)
✅ **App restarts** (force close and reopen)
✅ **Device restarts** (reboot phone)
✅ **Network changes** (WiFi to cellular)
✅ **Time passing** (days, weeks of normal use)
✅ **Background/foreground switching**

---

## How to Handle Token Changes

### Your Current Implementation (Already Handles This!)

```dart
// Automatic token refresh listener
_firebaseMessaging.onTokenRefresh.listen((newToken) {
  debugPrint('🔔 FCMService: Token refreshed: $newToken');
  _fcmToken = newToken;
  _saveTokenToBackend(newToken);  // ✅ Automatically saves to backend
  notifyListeners();
});
```

**This automatically:**
- ✅ Detects when token changes
- ✅ Gets the new token
- ✅ Saves it to backend
- ✅ Updates local storage

---

## Token Validation

### Invalid Token Scenarios:

When Firebase returns these errors, the token is invalid:

1. **`messaging/invalid-registration-token`**
   - Token format is invalid
   - Token was never valid

2. **`messaging/registration-token-not-registered`**
   - Token was deleted
   - Token expired
   - App was uninstalled

**Your backend code already handles this:**
```typescript
// If token is invalid, remove it from user
if (error.code === 'messaging/invalid-registration-token' || 
    error.code === 'messaging/registration-token-not-registered') {
  await this.usersService.update(userId, { fcmToken: undefined });
}
```

---

## Best Practices

### 1. Always Handle Token Refresh
✅ Your code already does this!

### 2. Save Token After Login
✅ Your code already does this in `auth_provider.dart`

### 3. Update Token When It Changes
✅ Your `onTokenRefresh` listener handles this automatically

### 4. Validate Tokens on Backend
✅ Your backend removes invalid tokens automatically

---

## Summary

### Token Changes When:
1. ❌ App reinstalled
2. 🔄 Firebase refreshes token (periodic security rotation)
3. 🧹 App data cleared
4. 📱 Device factory reset
5. 🔐 Firebase project reset
6. 🗑️ Manual token deletion
7. 🔄 Major Firebase SDK update (rare)
8. 📶 Significant device changes (very rare)

### Token Stays Same When:
- ✅ Normal app usage
- ✅ App updates
- ✅ Device restarts
- ✅ Network changes
- ✅ Time passing

---

## Most Common Scenario (Besides Reinstall)

**#2: Firebase Token Refresh**
- Happens automatically by Firebase
- Usually after long inactivity (weeks/months)
- Your code automatically handles it with `onTokenRefresh`
- No user action needed - it just works! ✅

---

**Bottom line:** The token is stable, but can change due to security refreshes, app data clearing, or significant changes. Your code already handles all these scenarios automatically! 🎉

