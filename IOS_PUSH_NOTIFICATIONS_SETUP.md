# iOS Push Notifications Setup - Complete Guide

Now that you have Apple Developer enrollment, let's set up push notifications for iOS!

## ⚠️ Important: Use APNs Auth Key (NOT SSL Certificates)

**Modern Approach (Recommended):** APNs Authentication Key (.p8 file)
- ✅ Easier to set up
- ✅ Never expires
- ✅ Works for all your apps
- ✅ Single key for all environments

**Old Approach (Not Recommended):** SSL Certificates
- ❌ More complex
- ❌ Expires yearly
- ❌ Separate certificates for dev/prod

We'll use the **APNs Auth Key** approach.

---

## Step 1: Create APNs Authentication Key

### 1.1 Go to Apple Developer Portal

1. Open: **https://developer.apple.com/account/resources/authkeys/list**
2. Sign in with your Apple Developer account
3. You should see a list of keys (might be empty if this is your first)

### 1.2 Create New Key

1. Click the **"+"** button (top left, next to "Keys")
2. Enter a **Key Name**: `Bottleji APNs Key` (or any descriptive name)
3. **IMPORTANT:** Check the box: **"Apple Push Notifications service (APNs)"**
4. Click **"Continue"**
5. Review the summary and click **"Register"**

### 1.3 Download the Key

⚠️ **CRITICAL:** You can **ONLY download this key ONCE**!

1. On the key details page, click the **"Download"** button
2. Save the `.p8` file (e.g., `AuthKey_XXXXXXXXXX.p8`)
   - **Save it in a secure location!**
   - **Never commit to git!**
   - **You cannot re-download if lost!**
3. **Note the Key ID** (shown on the page, e.g., `ABC123DEF4`)
4. **Note your Team ID** (shown at top right of the page, e.g., `XYZ987ABC6`)

**Save these three things:**
- ✅ `.p8` file (the key itself)
- ✅ Key ID (10 characters)
- ✅ Team ID (10 characters)

---

## Step 2: Upload APNs Key to Firebase Console

### 2.1 Go to Firebase Console

1. Open: **https://console.firebase.google.com/project/botleji/settings/cloudmessaging**
2. Or navigate: Firebase Console → Your Project → ⚙️ Settings → **Cloud Messaging** tab

### 2.2 Upload APNs Authentication Key

1. Scroll down to **"Apple app configuration"** section
2. Under **"APNs Authentication Key"**:
   - Click **"Upload"** button
   - Select your `.p8` file (the one you downloaded)
   - Enter the **Key ID** (from Step 1.3)
   - Enter your **Team ID** (from Step 1.3)
   - Click **"Upload"**

### 2.3 Verify Upload

1. You should see: **"APNs Authentication Key uploaded"** ✅
2. The status should show as configured
3. You should see a green checkmark or success message

---

## Step 3: Enable Push Notifications in Xcode

### 3.1 Open Xcode Workspace

```bash
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji/ios
open Runner.xcworkspace
```

⚠️ **IMPORTANT:** Use `.xcworkspace` NOT `.xcodeproj`

### 3.2 Add Push Notifications Capability

1. In Xcode, select **Runner** project (blue icon) in the left sidebar
2. Select **Runner** target (under TARGETS)
3. Click the **"Signing & Capabilities"** tab
4. Click **"+ Capability"** button (top left of the capabilities area)
5. Search for and add: **"Push Notifications"**
6. Click **"+ Capability"** again
7. Search for and add: **"Background Modes"**
8. In Background Modes, check: **"Remote notifications"**

### 3.3 Verify Automatic Signing

1. Still in **"Signing & Capabilities"** tab
2. Under **"Signing"** section:
   - ✅ Check **"Automatically manage signing"**
   - ✅ Select your **Team** (your Apple Developer account)
3. Xcode will automatically:
   - Create/update your App ID
   - Create provisioning profiles
   - Manage certificates

### 3.4 Verify Bundle ID

1. Still in **"Signing & Capabilities"** tab
2. Under **"Signing"**, verify:
   - **Bundle Identifier:** `com.example.botleji`
   - This should match your Firebase iOS app configuration

---

## Step 4: Verify Info.plist Configuration

Your `Info.plist` should already have the correct settings, but let's verify:

**File:** `botleji/ios/Runner/Info.plist`

Should contain:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <!-- other modes -->
</array>
```

✅ **Already configured!** (I can see it in your Info.plist)

---

## Step 5: Test on Physical Device

### 5.1 Important Notes

- ⚠️ **iOS Simulator does NOT support push notifications**
- ✅ **You MUST test on a physical iOS device**
- ✅ Device must be connected via USB or on same network

### 5.2 Connect Your Device

1. Connect your iPhone/iPad via USB
2. Unlock your device
3. Trust the computer if prompted
4. In Xcode, select your device from the device dropdown (top toolbar)

### 5.3 Build and Run

**Option A: Using Flutter**
```bash
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
flutter run -d <your-device-id>
```

**Option B: Using Xcode**
1. Select your device in Xcode
2. Click **Run** button (▶️) or press `Cmd + R`

### 5.4 Check Logs for FCM Token

After the app runs and you complete onboarding (grant notification permission), check the logs:

**Look for these logs:**
```
🔔 FCMService: iOS detected - getting APNS token first...
🔔 FCMService: APNS Token: [long token]
🔔 FCMService: FCM Token: [long token]
🔔 FCMService: FCM token saved to backend successfully
```

**If you see "APNS token is null":**
- ✅ Verify APNs key is uploaded to Firebase Console
- ✅ Check Key ID and Team ID are correct
- ✅ Ensure app is running on **physical device** (not simulator)
- ✅ Verify Bundle ID matches in Firebase Console
- ✅ Make sure Push Notifications capability is enabled in Xcode

---

## Step 6: Test Push Notification

### 6.1 Get FCM Token from Logs

1. Run your app on a physical device
2. Complete onboarding and grant notification permission
3. Copy the FCM token from the logs (look for `🔔 FCMService: FCM Token: ...`)

### 6.2 Send Test Notification via Firebase Console

1. Go to: **https://console.firebase.google.com/project/botleji/notification**
2. Click **"Send your first message"** or **"New notification"**
3. Enter:
   - **Notification title**: "Test from Firebase"
   - **Notification text**: "This is a test push notification!"
4. Click **"Next"**
5. Under **"Send test message"**:
   - Paste your FCM token
   - Click **"Test"**
6. You should receive the notification on your device! 🎉

### 6.3 Test Different Scenarios

**Foreground (App Open):**
- Notification should appear as a local notification
- Check logs: `🔔 FCMService: Foreground message received`

**Background (App Minimized):**
- Notification should appear in notification center
- Tapping it should open the app

**Terminated (App Closed):**
- Notification should appear in notification center
- Tapping it should open the app
- Check logs: `🔔 FCMService: App opened from terminated state via notification`

---

## Troubleshooting

### Issue: "APNS token is null" on Physical Device

**Possible causes:**
1. APNs key not uploaded to Firebase Console
2. Wrong Key ID or Team ID
3. Bundle ID mismatch
4. App not properly signed

**Solutions:**
1. ✅ Verify APNs key is uploaded in Firebase Console
2. ✅ Double-check Key ID and Team ID are correct
3. ✅ Verify Bundle ID in Firebase Console matches your app (`com.example.botleji`)
4. ✅ Ensure app is signed with your developer account in Xcode
5. ✅ Clean build: **Product** → **Clean Build Folder** (`Shift + Cmd + K`)

### Issue: "Invalid APNs credentials" Error

**Solutions:**
- Re-upload the APNs key with correct Key ID and Team ID
- Make sure you're using the `.p8` file (not a certificate)
- Verify Team ID matches your Apple Developer account

### Issue: Notifications Not Received

**Check:**
1. ✅ Device notification permissions are granted (Settings → Bottleji → Notifications)
2. ✅ App is not in "Do Not Disturb" mode
3. ✅ Device has internet connection
4. ✅ FCM token is valid (check Firebase Console)
5. ✅ APNs key is uploaded and valid
6. ✅ App is running on physical device (not simulator)

### Issue: "Code signing failed"

**Solutions:**
1. Enable "Automatically manage signing" in Xcode
2. Select correct Team
3. Clean build folder: **Product** → **Clean Build Folder**
4. Delete derived data: **Xcode** → **Settings** → **Locations** → **Derived Data** → Delete

---

## Quick Checklist

Before testing, verify:

- [ ] Apple Developer Program membership active ✅
- [ ] APNs Authentication Key created (.p8 file)
- [ ] APNs key downloaded and saved securely
- [ ] Key ID and Team ID noted
- [ ] APNs key uploaded to Firebase Console
- [ ] Bundle ID verified in Firebase Console (`com.example.botleji`)
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes → Remote notifications enabled
- [ ] Automatic signing enabled in Xcode
- [ ] Team selected in Xcode
- [ ] Physical iOS device connected
- [ ] App built and run on physical device
- [ ] Notification permission granted
- [ ] FCM token generated successfully
- [ ] Test notification received

---

## Important Links

- **Apple Developer Portal:** https://developer.apple.com/account
- **APNs Keys:** https://developer.apple.com/account/resources/authkeys/list
- **Firebase Console:** https://console.firebase.google.com/project/botleji
- **Cloud Messaging Settings:** https://console.firebase.google.com/project/botleji/settings/cloudmessaging
- **Send Test Notification:** https://console.firebase.google.com/project/botleji/notification

---

## Security Notes

⚠️ **CRITICAL:**
- **Never commit** `.p8` files to git
- Store `.p8` files securely (password manager, encrypted drive)
- **Backup** `.p8` files (you can only download once!)
- If compromised, revoke and create a new key
- Add `.p8` to `.gitignore` if not already there

---

## What's Next?

Once push notifications are working:

1. ✅ Test all notification scenarios (foreground, background, terminated)
2. ✅ Verify token refresh works
3. ✅ Test backend notification sending
4. ✅ Configure notification payloads for your use cases
5. ✅ Set up notification categories and actions (if needed)

---

## Summary

**You need to do these 3 main things:**

1. ✅ **Create APNs Auth Key** → Download `.p8` file (save securely!)
2. ✅ **Upload to Firebase** → Firebase Console → Cloud Messaging → Upload `.p8` with Key ID and Team ID
3. ✅ **Enable in Xcode** → Add "Push Notifications" capability + "Background Modes" → "Remote notifications"

That's it! Once these are done, your iOS app will be able to receive push notifications. 🎉

