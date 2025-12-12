# Debug: Not Receiving Notifications

## Step-by-Step Debugging

### Step 1: Check FCM Token is Generated

**In Flutter logs, look for:**
```
✅ FCMService: APNS Token received: [token]
🔔 FCMService: FCM Token: [token]
```

**If you don't see this:**
- App might not be initialized
- APNS might not be configured
- Check if you're on a physical device (not simulator)

---

### Step 2: Check FCM Token is Saved to Backend

**In Flutter logs, look for:**
```
🔔 FCMService: Saving FCM token to backend...
🔔 FCMService: FCM token saved to backend successfully
```

**If you see:**
```
🔔 FCMService: No auth token, skipping token save to backend
```
**Problem:** User not logged in - token won't be saved until login

**To verify in database:**
- Check MongoDB: `users` collection
- Find your user document
- Check `fcmToken` field - should have a token value

---

### Step 3: Check Backend is Sending Notifications

**In backend logs (Render dashboard), look for:**
```
📤 ===== SENDING NOTIFICATION =====
📤 User ID: [userId]
📤 Notification type: [type]
📱 Attempting to send notification via FCM to user [userId]...
✅ FCM notification sent successfully to user [userId]
```

**If you see:**
```
⚠️ FCM notification failed for user [userId] (user may not have FCM token)
```
**Problem:** User doesn't have FCM token in database

---

### Step 4: Check Notification Permissions

**In Flutter logs, look for:**
```
🔔 FCMService: Permission status: AuthorizationStatus.authorized
🔔 FCMService: User granted permission
```

**If you see:**
```
🔔 FCMService: User denied or has not accepted permission
```
**Problem:** Notification permissions not granted

**Fix:**
- Go to Settings → Bottleji → Notifications
- Enable notifications

---

### Step 5: Check App State

**Notifications work differently based on app state:**

1. **App in foreground:**
   - FCM sends notification to `onMessage` handler
   - Your code should show local notification
   - Check logs for: `🔔 FCMService: Foreground message received`

2. **App in background:**
   - System shows notification automatically
   - Should appear in notification tray

3. **App terminated:**
   - System shows notification automatically
   - Tapping opens app

---

### Step 6: Test with Firebase Console

**Quick test:**
1. Get your FCM token from logs
2. Go to Firebase Console → Cloud Messaging
3. Send test message with your token
4. If this works → Backend issue
5. If this doesn't work → FCM configuration issue

---

## Common Issues & Fixes

### Issue 1: Token Not Saved to Backend

**Symptoms:**
- Logs show: "No auth token, skipping token save"
- Database shows no `fcmToken` for user

**Fix:**
- Make sure user is logged in
- Token will be saved automatically after login
- Or manually call: `FCMService().saveTokenToBackend()` after login

---

### Issue 2: Backend Can't Find User Token

**Symptoms:**
- Backend logs: "User [userId] does not have an FCM token"
- Backend logs: "FCM notification failed"

**Fix:**
- Verify user has `fcmToken` in database
- If missing, user needs to log in again to save token
- Check user ID matches between frontend and backend

---

### Issue 3: Notifications Not Showing in Foreground

**Symptoms:**
- Logs show notification received
- But no push notification appears

**Fix:**
- This is expected - foreground notifications need manual handling
- Your code should show local notification
- Check `LocalNotificationService.showNotification()` is being called

---

### Issue 4: Backend Not Deployed Yet

**Symptoms:**
- Just pushed changes
- Render still deploying

**Fix:**
- Wait for deployment to complete
- Check Render dashboard for deployment status
- Should see "Live" status

---

## Quick Diagnostic Commands

### Check FCM Token in App:
```dart
// Add this temporarily to check token
final fcmService = FCMService();
final token = await fcmService.getCurrentToken();
print('Current FCM Token: $token');
```

### Check Backend Logs:
1. Go to Render dashboard
2. Click your service
3. Click "Logs" tab
4. Look for notification sending logs

### Check Database:
```javascript
// In MongoDB, check user document
db.users.findOne({ email: "your-email@example.com" })
// Look for: fcmToken field
```

---

## Test Checklist

- [ ] FCM token generated (check logs)
- [ ] FCM token saved to backend (check logs)
- [ ] User has fcmToken in database (check MongoDB)
- [ ] Notification permissions granted (check logs)
- [ ] Backend deployment complete (check Render)
- [ ] Backend sending notification (check backend logs)
- [ ] App receiving notification (check Flutter logs)

---

**Start with Step 1 and work through each step. Share what you find!**

