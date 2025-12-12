# FCM Token Refresh Fix

## Problem

You were seeing this error:
```
FirebaseMessagingError: Requested entity was not found.
code: 'messaging/registration-token-not-registered'
```

This means the FCM token stored in the database for the user is **invalid or expired**.

## What Happened

1. **User's FCM token changed** (app reinstall, data clear, or Firebase rotation)
2. **Old token still in database** (not updated)
3. **Backend tries to send notification** using old token
4. **Firebase rejects it** → "registration-token-not-registered"
5. **Backend correctly removes invalid token** and falls back to WebSocket

## Solution

I added a check to **automatically save the FCM token** when the app starts with a logged-in user. This ensures:

1. ✅ Token is refreshed if it changed
2. ✅ Token is saved to backend automatically
3. ✅ Prevents stale token errors

## What Changed

**File:** `botleji/lib/main.dart`

Added code in `MainAppScreen` to ensure FCM token is saved when user is logged in:

```dart
// Ensure FCM token is saved when user is logged in (in case token changed)
WidgetsBinding.instance.addPostFrameCallback((_) {
  try {
    final fcmService = FCMService();
    // If FCM is initialized, save the current token to backend
    if (fcmService.initialized) {
      fcmService.saveTokenToBackend().catchError((e) {
        AppLogger.log('⚠️ Error saving FCM token on app start: $e');
      });
    }
  } catch (e) {
    AppLogger.log('⚠️ Error ensuring FCM token is saved: $e');
  }
});
```

## How It Works

1. **When app starts** and user is already logged in
2. **Check if FCM is initialized**
3. **If yes, save current token to backend**
4. **Token refresh listener** also automatically saves new tokens when they change

## Testing

After this fix:

1. **User opens app** (already logged in)
2. **FCM token is automatically saved** to backend
3. **Try sending notification** (e.g., lock/unlock user)
4. **Should work now!** ✅

## What to Do Now

**For the user who had the invalid token:**

1. **Open the app** (they're already logged in)
2. **The token will be automatically refreshed and saved**
3. **Try sending a notification again** - it should work!

**No action needed** - the fix is automatic! 🎉

---

## Additional Notes

- The backend **correctly handles** invalid tokens by removing them and falling back to WebSocket
- The token refresh listener (`onTokenRefresh`) also automatically saves new tokens
- This fix ensures tokens are saved even if the refresh listener hasn't fired yet

