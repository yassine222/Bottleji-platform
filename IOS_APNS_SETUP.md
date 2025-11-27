# iOS APNs Configuration for FCM - Step by Step

This guide will walk you through configuring Apple Push Notification Service (APNs) for Firebase Cloud Messaging on iOS.

## Prerequisites

- Apple Developer Account (paid membership required)
- Access to Apple Developer Portal: https://developer.apple.com/account
- Your iOS app's Bundle ID

---

## Step 1: Create APNs Authentication Key

### 1.1 Go to Apple Developer Portal

1. Open: https://developer.apple.com/account/resources/authkeys/list
2. Sign in with your Apple Developer account

### 1.2 Create New Key

1. Click the **"+"** button (top left, next to "Keys")
2. Enter a **Key Name**: `Bottleji APNs Key` (or any name you prefer)
3. Check the box: **"Apple Push Notifications service (APNs)"**
4. Click **"Continue"**
5. Review and click **"Register"**

### 1.3 Download the Key

1. **IMPORTANT**: You can only download this key **ONCE**!
2. Click **"Download"** button
3. Save the `.p8` file (e.g., `AuthKey_XXXXXXXXXX.p8`)
4. **Note the Key ID** shown on the page (you'll need this later)
5. **Note your Team ID** (shown at top right of the page)

**⚠️ CRITICAL**: Save this `.p8` file securely - you cannot download it again!

---

## Step 2: Upload APNs Key to Firebase Console

### 2.1 Go to Firebase Console

1. Open: https://console.firebase.google.com/project/botleji/settings/cloudmessaging
2. Or navigate: Firebase Console → Your Project → ⚙️ Settings → Cloud Messaging

### 2.2 Upload APNs Authentication Key

1. Scroll down to **"Apple app configuration"** section
2. Under **"APNs Authentication Key"**:
   - Click **"Upload"** button
   - Select your `.p8` file (the one you downloaded in Step 1.3)
   - Enter the **Key ID** (from Step 1.3)
   - Enter your **Team ID** (from Step 1.3)
   - Click **"Upload"**

### 2.3 Verify Upload

1. You should see: **"APNs Authentication Key uploaded"**
2. The status should show as configured

---

## Step 3: Verify iOS App Configuration

### 3.1 Check Bundle ID

1. In Firebase Console, go to: Project Settings → General
2. Under "Your apps", find your iOS app
3. Verify the Bundle ID matches your Flutter app's Bundle ID

### 3.2 Check GoogleService-Info.plist

1. Make sure `GoogleService-Info.plist` is in your `ios/Runner/` directory
2. This file should already be there if you've set up Firebase Auth

---

## Step 4: Test on Physical Device

### 4.1 Important Notes

- **iOS Simulator does NOT support push notifications**
- You **MUST** test on a **physical iOS device**
- Make sure your device is registered in Apple Developer Portal (if needed)

### 4.2 Run on Physical Device

1. Connect your iPhone/iPad via USB
2. In Xcode, select your device as the build target
3. Run: `flutter run -d <device-id>`
4. Or use Xcode to build and run

### 4.3 Check Logs

You should now see:
```
🔔 FCMService: iOS detected - getting APNS token first...
🔔 FCMService: APNS Token: [token]
🔔 FCMService: FCM Token: [token]
```

If you still see "APNS token is null", check:
- Device is connected and selected
- App is running on physical device (not simulator)
- APNs key is uploaded to Firebase Console
- Bundle ID matches in Firebase Console

---

## Step 5: Test Push Notification

### 5.1 Get FCM Token

1. Run your app on a physical device
2. Check Flutter logs for FCM token
3. Copy the token

### 5.2 Send Test Notification

1. Go to: https://console.firebase.google.com/project/botleji/notification
2. Click **"Send your first message"**
3. Enter title and text
4. Click **"Send test message"**
5. Paste your FCM token
6. Click **"Test"**
7. You should receive the notification on your device!

---

## Troubleshooting

### "APNS token is null" on Physical Device

**Possible causes:**
1. APNs key not uploaded to Firebase Console
2. Wrong Key ID or Team ID
3. Bundle ID mismatch
4. App not properly signed with your developer certificate

**Solutions:**
1. Verify APNs key is uploaded in Firebase Console
2. Double-check Key ID and Team ID
3. Verify Bundle ID in Firebase Console matches your app
4. Make sure app is signed with your developer account

### "Invalid APNs credentials" Error

**Solution:**
- Re-upload the APNs key with correct Key ID and Team ID
- Make sure you're using the `.p8` file (not a certificate)

### Notifications Not Received

**Check:**
1. Device notification permissions are granted
2. App is not in "Do Not Disturb" mode
3. Device has internet connection
4. FCM token is valid (check Firebase Console)

---

## Quick Checklist

- [ ] Created APNs Authentication Key in Apple Developer Portal
- [ ] Downloaded `.p8` file (saved securely)
- [ ] Noted Key ID and Team ID
- [ ] Uploaded `.p8` file to Firebase Console
- [ ] Entered correct Key ID and Team ID
- [ ] Verified Bundle ID matches
- [ ] Testing on physical device (not simulator)
- [ ] App has notification permissions
- [ ] FCM token is generated successfully
- [ ] Test notification received

---

## Important Links

- Apple Developer Portal: https://developer.apple.com/account
- APNs Keys: https://developer.apple.com/account/resources/authkeys/list
- Firebase Console: https://console.firebase.google.com/project/botleji
- Cloud Messaging Settings: https://console.firebase.google.com/project/botleji/settings/cloudmessaging

---

## Security Notes

- **Never commit** `.p8` files to git
- Store `.p8` files securely
- If compromised, revoke and create a new key
- The `.p8` file can only be downloaded once

---

## Next Steps

Once APNs is configured:
1. ✅ FCM tokens will be generated on iOS
2. ✅ Push notifications will work on physical devices
3. ✅ Background notifications will be delivered
4. ✅ Your backend can send notifications to iOS users

