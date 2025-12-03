# iOS Certificates and Keys Guide

This guide covers all the certificates, keys, and configurations needed for iOS development, specifically for:
- ✅ Firebase Cloud Messaging (FCM) push notifications
- ✅ Firebase Phone Authentication (OTP via SMS)
- ✅ App signing and distribution

---

## Prerequisites

- ✅ **Apple Developer Program membership** (paid - $99/year)
- ✅ Access to [Apple Developer Portal](https://developer.apple.com/account)
- ✅ Your app's Bundle ID: `com.example.botleji`

---

## Overview: What You Need

### 1. **APNs Authentication Key** (.p8 file) ⭐ **MOST IMPORTANT**
   - **Purpose:** Enables push notifications (FCM) and Phone Auth
   - **Where:** Apple Developer Portal → Keys
   - **Used by:** Firebase Console
   - **Status:** ✅ Can create once approved

### 2. **App ID** (with Push Notifications capability)
   - **Purpose:** Identifies your app and enables capabilities
   - **Where:** Apple Developer Portal → Identifiers
   - **Status:** ✅ Usually auto-created by Xcode

### 3. **Provisioning Profiles** (Development & Distribution)
   - **Purpose:** Links your app, certificates, and devices
   - **Where:** Apple Developer Portal → Profiles
   - **Status:** ✅ Usually auto-managed by Xcode

### 4. **Development/Distribution Certificates** (Optional)
   - **Purpose:** Code signing (usually auto-managed)
   - **Where:** Apple Developer Portal → Certificates
   - **Status:** ✅ Usually auto-created by Xcode

---

## Step 1: APNs Authentication Key (.p8) ⭐

This is the **most important** certificate for FCM and Phone Auth.

### 1.1 Create APNs Key

1. Go to [Apple Developer Portal - Keys](https://developer.apple.com/account/resources/authkeys/list)
2. Click **"+"** button (top left)
3. Enter **Key Name**: `Bottleji APNs Key`
4. Check **"Apple Push Notifications service (APNs)"**
5. Click **"Continue"** → **"Register"**

### 1.2 Download the Key

⚠️ **CRITICAL:** You can only download this **ONCE**!

1. Click **"Download"** button
2. Save the `.p8` file (e.g., `AuthKey_XXXXXXXXXX.p8`)
3. **Note the Key ID** (shown on the page)
4. **Note your Team ID** (top right of the page)

**Save securely:**
- Store in a secure location (password manager, encrypted drive)
- **Never commit to git**
- You cannot re-download if lost

### 1.3 Upload to Firebase Console

1. Go to [Firebase Console - Cloud Messaging](https://console.firebase.google.com/project/botleji/settings/cloudmessaging)
2. Scroll to **"Apple app configuration"**
3. Under **"APNs Authentication Key"**:
   - Click **"Upload"**
   - Select your `.p8` file
   - Enter **Key ID**
   - Enter **Team ID**
   - Click **"Upload"**

✅ **This enables:**
- FCM push notifications on iOS
- Firebase Phone Auth SMS delivery
- Background notifications

---

## Step 2: App ID Configuration

### 2.1 Verify App ID Exists

1. Go to [Apple Developer Portal - Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Search for: `com.example.botleji`
3. If it doesn't exist, Xcode will create it automatically

### 2.2 Enable Push Notifications Capability

**Option A: Via Xcode (Recommended)**

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"**
5. Add **"Push Notifications"**
6. Add **"Background Modes"** → Check **"Remote notifications"**

**Option B: Via Apple Developer Portal**

1. Go to [Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click on your App ID (`com.example.botleji`)
3. Check **"Push Notifications"**
4. Click **"Save"**

✅ **This enables:**
- Push notification capability for your app
- Background notification delivery

---

## Step 3: Provisioning Profiles

### 3.1 Automatic Signing (Recommended)

Xcode can automatically manage provisioning profiles:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** (your Apple Developer account)
6. Xcode will automatically:
   - Create/update App ID
   - Create provisioning profiles
   - Manage certificates

✅ **This is the easiest approach!**

### 3.2 Manual Provisioning (If Needed)

If you need manual control:

1. Go to [Apple Developer Portal - Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Create **Development** profile:
   - Type: **iOS App Development**
   - App ID: `com.example.botleji`
   - Certificates: Select your development certificate
   - Devices: Select test devices
3. Create **Distribution** profile (for App Store):
   - Type: **App Store**
   - App ID: `com.example.botleji`
   - Certificates: Select your distribution certificate

---

## Step 4: Certificates (Usually Auto-Managed)

### 4.1 Development Certificate

**Auto-created by Xcode** when you enable automatic signing.

If you need to create manually:
1. Go to [Apple Developer Portal - Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click **"+"** button
3. Select **"iOS App Development"**
4. Follow the wizard (requires Keychain Access)

### 4.2 Distribution Certificate

**Auto-created by Xcode** when you build for distribution.

If you need to create manually:
1. Go to [Apple Developer Portal - Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click **"+"** button
3. Select **"App Store and Ad Hoc"**
4. Follow the wizard

---

## Step 5: Verify Configuration

### 5.1 Check Xcode Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project → **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. Verify:
   - ✅ **Team** is selected
   - ✅ **Bundle Identifier** is `com.example.botleji`
   - ✅ **"Automatically manage signing"** is checked
   - ✅ **Provisioning Profile** shows as valid
   - ✅ **Push Notifications** capability is added
   - ✅ **Background Modes** → **Remote notifications** is checked

### 5.2 Check Firebase Console

1. Go to [Firebase Console - Project Settings](https://console.firebase.google.com/project/botleji/settings/general)
2. Under **"Your apps"**, find your iOS app
3. Verify:
   - ✅ **Bundle ID** matches: `com.example.botleji`
   - ✅ **APNs Authentication Key** is uploaded (Cloud Messaging tab)

---

## Step 6: Test on Physical Device

### 6.1 Register Test Device (If Needed)

1. Connect your iPhone/iPad via USB
2. In Xcode: **Window** → **Devices and Simulators**
3. Your device should appear automatically
4. If not, click **"+"** to add device

### 6.2 Build and Run

```bash
cd botleji
flutter run -d <device-id>
```

Or use Xcode:
1. Select your device as build target
2. Click **Run** (▶️)

### 6.3 Verify FCM Token

Check logs for:
```
🔔 FCMService: iOS detected - getting APNS token first...
🔔 FCMService: APNS Token: [token]
🔔 FCMService: FCM Token: [token]
```

If you see **"APNS token is null"**, check:
- ✅ APNs key is uploaded to Firebase
- ✅ App is running on physical device (not simulator)
- ✅ Bundle ID matches in Firebase Console
- ✅ Push Notifications capability is enabled

---

## Summary: What You Need to Do

### Once Apple Developer Program is Approved:

1. ✅ **Create APNs Authentication Key** (.p8)
   - [Apple Developer Portal - Keys](https://developer.apple.com/account/resources/authkeys/list)
   - Download and save securely
   - Note Key ID and Team ID

2. ✅ **Upload APNs Key to Firebase**
   - [Firebase Console - Cloud Messaging](https://console.firebase.google.com/project/botleji/settings/cloudmessaging)
   - Upload .p8 file with Key ID and Team ID

3. ✅ **Enable Push Notifications in Xcode**
   - Open `ios/Runner.xcworkspace`
   - Add "Push Notifications" capability
   - Add "Background Modes" → "Remote notifications"

4. ✅ **Enable Automatic Signing**
   - Xcode → Signing & Capabilities
   - Check "Automatically manage signing"
   - Select your Team

5. ✅ **Test on Physical Device**
   - Run app on iPhone/iPad
   - Verify FCM token is generated
   - Test push notification

---

## Quick Reference

### Important Links

- **Apple Developer Portal:** https://developer.apple.com/account
- **APNs Keys:** https://developer.apple.com/account/resources/authkeys/list
- **App Identifiers:** https://developer.apple.com/account/resources/identifiers/list
- **Provisioning Profiles:** https://developer.apple.com/account/resources/profiles/list
- **Certificates:** https://developer.apple.com/account/resources/certificates/list
- **Firebase Console:** https://console.firebase.google.com/project/botleji
- **Firebase Cloud Messaging:** https://console.firebase.google.com/project/botleji/settings/cloudmessaging

### Your App Details

- **Bundle ID:** `com.example.botleji`
- **Project:** `botleji`
- **Firebase Project:** `botleji`

---

## Troubleshooting

### "APNs token is null" Error

**Causes:**
- APNs key not uploaded to Firebase
- Wrong Key ID or Team ID
- Bundle ID mismatch
- App not signed properly
- Running on simulator (use physical device)

**Solutions:**
- Verify APNs key is uploaded in Firebase Console
- Check Key ID and Team ID are correct
- Verify Bundle ID matches in Firebase and Xcode
- Ensure app is signed with your developer account
- Test on physical device, not simulator

### "Invalid APNs credentials" Error

**Solutions:**
- Re-upload APNs key with correct Key ID and Team ID
- Ensure you're using `.p8` file (not certificate)
- Check Team ID matches your Apple Developer account

### "Code signing failed" Error

**Solutions:**
- Enable "Automatically manage signing" in Xcode
- Select correct Team
- Clean build folder: **Product** → **Clean Build Folder**
- Delete derived data: **Xcode** → **Preferences** → **Locations** → **Derived Data** → **Delete**

### Push Notifications Not Received

**Check:**
- Device notification permissions are granted
- App is not in "Do Not Disturb" mode
- Device has internet connection
- FCM token is valid (check Firebase Console)
- APNs key is uploaded and valid
- App is running on physical device

---

## Security Best Practices

1. **Never commit** `.p8` files to git
2. **Store** `.p8` files securely (password manager, encrypted drive)
3. **Backup** `.p8` files (you can only download once)
4. **Revoke** and recreate if compromised
5. **Use** environment variables for production keys
6. **Rotate** keys periodically

---

## Next Steps

Once you have Apple Developer Program approval:

1. ✅ Create APNs Authentication Key
2. ✅ Upload to Firebase Console
3. ✅ Configure Xcode signing
4. ✅ Enable Push Notifications capability
5. ✅ Test on physical device
6. ✅ Verify FCM tokens are generated
7. ✅ Test push notifications

---

## Additional Resources

- **iOS APNs Setup Guide:** `docs/setup/IOS_APNS_SETUP.md`
- **FCM Setup Guide:** `docs/setup/FCM_SETUP_GUIDE.md`
- **Firebase Phone Auth:** `FIREBASE_PHONE_AUTH_SETUP.md`
- **Apple Developer Documentation:** https://developer.apple.com/documentation/usernotifications

---

## Checklist

Before testing iOS push notifications:

- [ ] Apple Developer Program membership active
- [ ] APNs Authentication Key created (.p8 file)
- [ ] APNs key downloaded and saved securely
- [ ] Key ID and Team ID noted
- [ ] APNs key uploaded to Firebase Console
- [ ] Bundle ID verified in Firebase Console
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes → Remote notifications enabled
- [ ] Automatic signing enabled in Xcode
- [ ] Physical iOS device connected
- [ ] App built and run on physical device
- [ ] FCM token generated successfully
- [ ] Test notification received

---

**Ready to configure iOS once Apple Developer Program is approved!** 🎉



