# Fix APNS Token Null Issue

## Problem
APNS token is null even though:
- ✅ On physical device
- ✅ Notification permission granted
- ✅ Push Notifications capability enabled in Xcode
- ✅ APNs key uploaded to Firebase

## Solution

### Step 1: Verify Provisioning Profile Has Push Notifications

**In Xcode:**

1. Open `Runner.xcworkspace`
2. Select **Runner** project → **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. Look at the **Provisioning Profile** section:
   - Should show: `"iOS Team Provisioning Profile: com.example.botleji"`
   - Or similar provisioning profile name
   - Should NOT show any errors (red text)

**If you see errors:**
- Click the **"i"** icon next to the provisioning profile
- Check what capabilities are included
- Push Notifications should be listed

---

### Step 2: Force Regenerate Provisioning Profile

**Option A: Automatic Signing (Recommended)**

1. In Xcode, **Signing & Capabilities** tab
2. **Uncheck** "Automatically manage signing"
3. Wait a moment
4. **Check** "Automatically manage signing" again
5. Select your **Team**: "Yassine Romdhane (LXP2TU6LL6)"
6. Xcode will regenerate the provisioning profile with Push Notifications

**Option B: Via Apple Developer Portal**

1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Find your **Development** profile for `com.example.botleji`
3. If it doesn't have Push Notifications:
   - Click **Edit**
   - Check **Push Notifications**
   - Click **Generate**
   - Download the new profile
4. In Xcode, **Signing & Capabilities** → Select the new profile

---

### Step 3: Clean Build and Rebuild

**Important: You MUST rebuild after changing capabilities!**

```bash
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
flutter run
```

**Or in Xcode:**
1. **Product** → **Clean Build Folder** (Shift+Cmd+K)
2. **Product** → **Build** (Cmd+B)
3. **Product** → **Run** (Cmd+R)

---

### Step 4: Verify App ID Has Push Notifications

**In Apple Developer Portal:**

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Find: `com.example.botleji`
3. Click on it
4. Check **"Push Notifications"** is enabled
5. If not:
   - Check **Push Notifications**
   - Click **Save**
   - Regenerate provisioning profile (Step 2)

---

### Step 5: Check Firebase Configuration

**Verify Bundle ID matches:**

1. Firebase Console: https://console.firebase.google.com/project/botleji/settings/general
2. Under "Your apps", find iOS app
3. Verify Bundle ID: `com.example.botleji`
4. Verify APNs Authentication Key is uploaded:
   - Go to: Cloud Messaging tab
   - Check "APNs Authentication Key" shows as configured

---

## Why This Happens

**APNS token is null because:**
- The provisioning profile doesn't include Push Notifications capability
- The app was built before adding Push Notifications capability
- The App ID doesn't have Push Notifications enabled
- There's a mismatch between Xcode, provisioning profile, and App ID

---

## Debugging Checklist

- [ ] App is running on **physical device** (not simulator) ✅
- [ ] Push Notifications capability added in Xcode
- [ ] Background Modes → Remote notifications enabled
- [ ] Provisioning profile includes Push Notifications
- [ ] App ID has Push Notifications enabled in Apple Developer Portal
- [ ] App rebuilt after adding capability
- [ ] Xcode shows no signing errors
- [ ] APNs key uploaded to Firebase
- [ ] Bundle ID matches in Firebase and Xcode

---

## Expected Result

After fixing, you should see:

```
🔔 FCMService: iOS detected - getting APNS token first...
🔔 FCMService: APNS Token: [64-character hex string]
🔔 FCMService: FCM Token: [long token]
```

Instead of:
```
⚠️ FCMService: APNS token is null
```

---

## Quick Fix (Try This First)

1. **Xcode** → **Signing & Capabilities**
2. **Uncheck** "Automatically manage signing"
3. **Check** "Automatically manage signing" again
4. Select **Team**: "Yassine Romdhane (LXP2TU6LL6)"
5. **Clean Build Folder** (Shift+Cmd+K)
6. **Run** again (Cmd+R)

This forces Xcode to regenerate the provisioning profile with Push Notifications included.


