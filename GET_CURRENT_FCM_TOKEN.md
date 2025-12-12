# How to Get Current FCM Token

## Quick Methods

### Method 1: Check App Logs (Easiest)

**When you run the app, it automatically logs the FCM token:**

1. **Run the app:**
   ```bash
   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
   flutter run
   ```

2. **Complete onboarding** (if needed)

3. **Look for this log:**
   ```
   🔔 FCMService: FCM Token: [your current token]
   ```

4. **Copy the token** and use it in Firebase Console

---

### Method 2: Check Logs After App Restart

**The token is logged every time FCM initializes:**

- When app starts
- After notification permission is granted
- After login (if token refresh happens)

**Just restart the app and check logs!**

---

### Method 3: Use the getCurrentToken Method

**I added a method to get the current token. You can call it from anywhere:**

```dart
final fcmService = FCMService();
final currentToken = await fcmService.getCurrentToken();
print('Current FCM Token: $currentToken');
```

**This will log the token in the console.**

---

### Method 4: Check SharedPreferences

**The token is also saved locally:**

The token is stored in SharedPreferences with key `'fcm_token'`, but you'd need to add code to read it.

---

## Why Token Changed

**The token can change when:**
- ✅ App was reinstalled
- ✅ App data was cleared
- ✅ Firebase rotated the token
- ✅ Significant time passed

**This is normal behavior!**

---

## Best Practice

**Always use the CURRENT token from logs, not an old one!**

When testing:
1. ✅ Run the app
2. ✅ Copy the FCM token from logs
3. ✅ Use it immediately in Firebase Console
4. ✅ Don't use old tokens!

---

## Quick Command to See Token

**Just run the app and watch for:**
```
🔔 FCMService: FCM Token: [token]
```

**That's your current token!**

---

**Easiest: Just restart the app and copy the token from the logs!**


