# Firebase Cloud Messaging (FCM) Setup Guide

This guide will walk you through configuring FCM for push notifications in your Bottleji app.

## Prerequisites

- Firebase project already created (you're using Firebase Auth, so this should be done)
- Access to Firebase Console: https://console.firebase.google.com
- Backend server running
- Flutter app with Firebase already initialized

---

## Step 1: Get Firebase Service Account Key (Backend)

### 1.1 Go to Firebase Console
1. Open https://console.firebase.google.com
2. Select your project: **botleji**

### 1.2 Navigate to Project Settings
1. Click the **gear icon** (⚙️) next to "Project Overview"
2. Select **Project settings**

### 1.3 Go to Service Accounts Tab
1. Click on the **"Service accounts"** tab
2. You'll see "Firebase Admin SDK" section

### 1.4 Generate New Private Key
1. Click **"Generate new private key"** button
2. A dialog will appear - click **"Generate key"**
3. A JSON file will be downloaded (e.g., `botleji-firebase-adminsdk-xxxxx.json`)

### 1.5 Configure Backend Environment Variable

**Option A: Using Environment Variable (Recommended for Production)**

1. Open the downloaded JSON file
2. Copy the entire JSON content
3. In your backend `.env` file, add:
   ```env
   FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"botleji",...}'
   ```
   ⚠️ **Important**: The entire JSON must be on a single line, or use proper escaping

**Option B: Using Service Account File (Easier for Development)**

1. Copy the downloaded JSON file to your backend directory:
   ```bash
   cp ~/Downloads/botleji-firebase-adminsdk-xxxxx.json backend/firebase-service-account.json
   ```

2. Update `backend/src/modules/notifications/fcm.service.ts`:
   ```typescript
   private initializeFirebase() {
     try {
       if (!admin.apps.length) {
         // Option B: Use service account file
         const serviceAccount = require('../../firebase-service-account.json');
         
         this.firebaseApp = admin.initializeApp({
           credential: admin.credential.cert(serviceAccount),
         });
         this.logger.log('Firebase Admin SDK initialized successfully');
       }
     } catch (error) {
       this.logger.error('Error initializing Firebase Admin SDK:', error);
     }
   }
   ```

3. Add to `.gitignore`:
   ```
   backend/firebase-service-account.json
   ```

---

## Step 2: Configure iOS for FCM (APNs)

### 2.1 Get APNs Authentication Key from Apple Developer

1. Go to https://developer.apple.com/account/resources/authkeys/list
2. Click the **"+"** button to create a new key
3. Enter a name (e.g., "Bottleji APNs Key")
4. Check **"Apple Push Notifications service (APNs)"**
5. Click **"Continue"** then **"Register"**
6. Download the `.p8` key file (you can only download it once!)
7. Note the **Key ID** shown on the page

### 2.2 Upload APNs Key to Firebase

1. Go to Firebase Console → Your Project
2. Click **⚙️ Project settings**
3. Go to **"Cloud Messaging"** tab
4. Scroll to **"Apple app configuration"** section
5. Under **"APNs Authentication Key"**:
   - Click **"Upload"**
   - Select your `.p8` file
   - Enter the **Key ID** you noted earlier
   - Enter your **Team ID** (found in Apple Developer account)
   - Click **"Upload"**

**Alternative: Using APNs Certificate (if you prefer)**
- You can also upload an APNs Certificate (.p12 file) instead of the key

### 2.3 Verify iOS Configuration

1. In Firebase Console → Project Settings → Cloud Messaging
2. Check that **"APNs Authentication Key"** shows as configured
3. Your iOS app should automatically use this configuration

---

## Step 3: Configure Android (Usually Automatic)

Android should work automatically, but verify:

1. In Firebase Console → Project Settings → Cloud Messaging
2. Check that **"Server key"** is visible (you'll need this for testing)
3. Your `google-services.json` file should already be in `android/app/`

### 3.1 Verify Android Notification Channel

The code uses channel ID `'bottleji_notifications'`. This should be created automatically by `flutter_local_notifications`, but you can verify in your Android code if needed.

---

## Step 4: Test the Configuration

### 4.1 Start Backend Server

```bash
cd backend
npm run start:dev
```

Check the logs - you should see:
```
Firebase Admin SDK initialized successfully
```

If you see an error, check:
- Service account key is correctly configured
- JSON format is valid
- File path is correct (if using file method)

### 4.2 Run Flutter App

```bash
cd botleji
flutter run
```

Check the logs - you should see:
```
🔔 FCMService: Initializing Firebase Cloud Messaging...
🔔 FCMService: Permission status: AuthorizationStatus.authorized
🔔 FCMService: FCM Token: [long token string]
🔔 FCMService: FCM token saved to backend successfully
```

### 4.3 Verify Token in Database

1. Check your MongoDB database
2. Find a user document
3. Verify that `fcmToken` field is populated with a token

### 4.4 Test Push Notification (Using Firebase Console)

1. Go to Firebase Console → **Cloud Messaging**
2. Click **"Send your first message"** or **"New notification"**
3. Enter:
   - **Notification title**: "Test Notification"
   - **Notification text**: "This is a test"
4. Click **"Next"**
5. Select **"Send test message"**
6. Enter the FCM token from your app logs
7. Click **"Test"**
8. You should receive the notification on your device!

---

## Step 5: Verify Backend Integration

### 5.1 Test Notification via Backend

When a notification is sent and the user is NOT connected via WebSocket, the backend should:
1. Detect user is not connected
2. Send via FCM instead
3. Log: `✅ FCM notification sent to user [userId]`

### 5.2 Check Backend Logs

When testing, watch for:
```
⚠️ User [userId] is NOT connected to WebSocket, sending via FCM
✅ FCM notification sent to user [userId]
```

---

## Troubleshooting

### Backend: "Firebase Admin SDK not initialized"

**Solution:**
- Verify service account key is correctly set in environment variable or file
- Check JSON format is valid
- Ensure file path is correct (if using file method)

### iOS: Notifications not received

**Solution:**
- Verify APNs key is uploaded to Firebase Console
- Check that your iOS app has notification permissions enabled
- Verify your iOS app is using the correct Firebase configuration
- Check device logs for FCM errors

### Android: Notifications not received

**Solution:**
- Verify `google-services.json` is in `android/app/`
- Check notification permissions are granted
- Verify notification channel is created
- Check device logs for FCM errors

### Token not saving to backend

**Solution:**
- Check that user is logged in (auth token exists)
- Verify `/auth/fcm-token` endpoint is accessible
- Check backend logs for errors
- Verify API client is correctly configured

### "Invalid registration token" error

**Solution:**
- Token might be expired - app will automatically refresh it
- User might have uninstalled/reinstalled app
- Token format might be incorrect

---

## Security Notes

1. **Never commit** `firebase-service-account.json` to git
2. **Never commit** `.p8` APNs key files to git
3. Use environment variables for production
4. Rotate keys periodically
5. Restrict service account permissions in Firebase Console

---

## Next Steps

Once configured:
1. ✅ Notifications will work in background
2. ✅ Notifications will work when app is closed
3. ✅ WebSocket will still be used when app is in foreground (faster)
4. ✅ FCM will be used as fallback when WebSocket is not available

---

## Quick Reference

### Backend Environment Variables
```env
FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account",...}'
```

### Firebase Console Links
- Project Settings: https://console.firebase.google.com/project/botleji/settings/general
- Cloud Messaging: https://console.firebase.google.com/project/botleji/settings/cloudmessaging
- Service Accounts: https://console.firebase.google.com/project/botleji/settings/serviceaccounts/adminsdk

### Important Files
- Backend: `backend/src/modules/notifications/fcm.service.ts`
- Flutter: `botleji/lib/core/services/fcm_service.dart`
- User Schema: `backend/src/modules/users/schemas/user.schema.ts`

---

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Check backend logs for initialization errors
3. Check Flutter app logs for FCM token generation
4. Verify all configuration steps were completed

