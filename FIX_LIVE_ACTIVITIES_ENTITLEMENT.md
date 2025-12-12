# Fix Live Activities Entitlement Error

## Problem
Provisioning profile doesn't include `com.apple.developer.usernotifications.live-activities` entitlement.

## Solution

### Step 1: Verify App ID Has Live Activities Enabled

1. Go to: **https://developer.apple.com/account/resources/identifiers/list**
2. Search for: `com.example.botleji`
3. Click on it
4. Scroll to **"Capabilities"** section
5. **Check BOTH:**
   - ✅ **Push Notifications** (you already enabled this)
   - ✅ **Live Activities** (make sure this is also enabled!)
6. If Live Activities is NOT checked:
   - ✅ Check the box
   - ✅ Click **"Save"**

---

### Step 2: Regenerate Provisioning Profile in Xcode

**After enabling Live Activities in App ID:**

1. Open `Runner.xcworkspace` in Xcode
2. **Runner** project → **Runner** target
3. **Signing & Capabilities** tab
4. **Uncheck** "Automatically manage signing"
5. Wait 2 seconds
6. **Check** "Automatically manage signing" again
7. Select **Team**: "Yassine Romdhane (LXP2TU6LL6)"
8. **Wait for provisioning profile to regenerate** (watch for spinner)
9. Check for any red errors - should be gone now

**This forces Xcode to create a new provisioning profile with both capabilities!**

---

### Step 3: Verify Capabilities in Xcode

**In Signing & Capabilities tab, you should see:**

- ✅ **Push Notifications** capability
- ✅ **Background Modes** → Remote notifications checked
- ✅ **Live Activities** capability (if you added it)

**If Live Activities capability is missing:**
- Click **"+ Capability"**
- Add **"Live Activities"**

---

### Step 4: Clean and Rebuild

**After regenerating provisioning profile:**

```bash
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
flutter clean
cd ios
rm -rf Pods Podfile.lock build
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

### Step 5: Delete App from Device

**Important: Delete the app completely before reinstalling!**

1. On your iPhone:
   - Long press app icon
   - Tap "Remove App"
   - Tap "Delete App"

2. Reinstall after clean build

---

## Why This Happens

**The provisioning profile was created BEFORE Live Activities was enabled in the App ID.**

When you:
1. Enable Push Notifications in App ID ✅
2. But provisioning profile was created earlier ❌
3. Profile doesn't include Live Activities entitlement ❌

**Solution:** Regenerate provisioning profile after enabling capabilities!

---

## Quick Fix Summary

1. ✅ **Enable Live Activities in App ID** (Apple Developer Portal)
2. ✅ **Regenerate provisioning profile** (Xcode: uncheck/check automatic signing)
3. ✅ **Clean rebuild**
4. ✅ **Delete and reinstall app**
5. ✅ **Test again**

---

## Verification

**After fixing, you should see:**
- ✅ No red errors in Xcode Signing & Capabilities
- ✅ Provisioning profile includes both Push Notifications and Live Activities
- ✅ App builds successfully
- ✅ APNS token should work now!

---

**The key is: Enable Live Activities in App ID, then regenerate the provisioning profile!**


