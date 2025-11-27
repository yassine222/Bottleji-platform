# Testing FCM Integration

## Step 1: Run Flutter App

```bash
cd botleji
flutter run
```

**Check Flutter logs for:**
- `🔔 FCMService: Initializing Firebase Cloud Messaging...`
- `🔔 FCMService: FCM Token: [token]`
- `🔔 FCMService: FCM token saved to backend successfully`

## Step 2: Verify Token in Database

Check MongoDB:
```javascript
db.users.findOne({ email: "your-email@example.com" }, { fcmToken: 1 })
```

You should see the `fcmToken` field populated.

## Step 3: Test Push Notification via Firebase Console

1. Go to: https://console.firebase.google.com/project/botleji/notification
2. Click **"Send your first message"** or **"New notification"**
3. Enter:
   - **Title**: "Test Notification"
   - **Text**: "This is a test from Firebase Console"
4. Click **"Next"**
5. Click **"Send test message"**
6. Paste your FCM token from Flutter logs
7. Click **"Test"**
8. You should receive the notification on your device!

## Step 4: Test via Backend (When User is NOT Connected)

1. Make sure your Flutter app is **closed** or in **background**
2. Trigger a notification (e.g., accept a drop, send a ticket message)
3. Check backend logs - you should see:
   ```
   ⚠️ User [userId] is NOT connected to WebSocket, sending via FCM
   ✅ FCM notification sent to user [userId]
   ```
4. You should receive the push notification!

## Step 5: Test via Backend (When User IS Connected)

1. Make sure your Flutter app is **open and in foreground**
2. Trigger a notification
3. Check backend logs - you should see:
   ```
   ✅ User [userId] is connected, sending via WebSocket
   ✅ WebSocket notification sent to user [userId]
   ```
4. You should see the notification in-app (not as push)

## Troubleshooting

### No FCM Token Generated
- Check notification permissions are granted
- Check Firebase configuration is correct
- Check Flutter logs for errors

### Token Not Saved to Backend
- Check user is logged in
- Check `/auth/fcm-token` endpoint is accessible
- Check backend logs for errors

### Notifications Not Received
- **iOS**: Make sure APNs key is uploaded to Firebase Console
- **Android**: Should work automatically
- Check device notification settings
- Check Firebase Console for delivery status

### "Invalid registration token" Error
- Token might be expired - app will auto-refresh
- User might have reinstalled app
- Check backend logs for details

