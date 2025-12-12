# Fix: Provisioning Profile Missing Live Activities Entitlement

## Good News! ✅

Your entitlements file already has Live Activities:
```xml
<key>com.apple.developer.usernotifications.live-activities</key>
<true/>
```

**The problem:** The provisioning profile was created before this entitlement was added.

---

## Solution: Regenerate Provisioning Profile

**Live Activities is NOT a separate capability in App ID.** It's managed through:
- ✅ Entitlements file (you have this)
- ✅ Provisioning profile (needs to be regenerated)

---

### Step 1: In Xcode - Force Regenerate Provisioning Profile

1. Open `Runner.xcworkspace` in Xcode
2. **Runner** project → **Runner** target
3. **Signing & Capabilities** tab
4. **Uncheck** "Automatically manage signing"
5. Wait 3-5 seconds
6. **Check** "Automatically manage signing" again
7. Select **Team**: "Yassine Romdhane (LXP2TU6LL6)"
8. **Wait for provisioning profile to regenerate** (watch for spinner/updates)
9. Check for any errors - should be resolved now

**This creates a NEW provisioning profile that includes ALL entitlements from your entitlements file!**

---

### Step 2: Verify Capabilities in Xcode

**In Signing & Capabilities tab, you should see:**
- ✅ **Push Notifications** capability
- ✅ **Background Modes** → Remote notifications checked

**Note:** Live Activities might not show as a separate capability in the UI, but it's included via the entitlements file.

---

### Step 3: Check Code Signing Entitlements

**In Build Settings tab:**
1. Search for: "Code Signing Entitlements"
2. Should show: `Runner/Runner.entitlements`
3. If empty or different, set it to: `Runner/Runner.entitlements`

---

### Step 4: Clean and Rebuild

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

**Important:** Delete the app completely before reinstalling!

1. On iPhone:
   - Long press app icon
   - Tap "Remove App"
   - Tap "Delete App"

2. Reinstall after rebuild

---

## Why This Happens

**The provisioning profile is a snapshot** that includes:
- App ID capabilities
- Entitlements
- Certificates
- Devices

**When you:**
1. Add entitlements to the file ✅
2. But provisioning profile was created earlier ❌
3. Profile doesn't have the new entitlement ❌

**Solution:** Regenerate provisioning profile after adding entitlements!

---

## Verification

**After regenerating provisioning profile:**

The error should be gone. You should see:
- ✅ No red errors in Xcode
- ✅ Successful build
- ✅ App installs without errors

---

## Important Note

**Live Activities is NOT a capability you enable in App ID.**

Instead:
- ✅ You have it in `Runner.entitlements` (you do!)
- ✅ Enable **Push Notifications** in App ID (you did!)
- ✅ Regenerate provisioning profile (do this now!)

**The provisioning profile will automatically include Live Activities from your entitlements file!**

---

## Summary

1. ✅ Your entitlements file is correct (has Live Activities)
2. ✅ Push Notifications is enabled in App ID
3. ❌ Provisioning profile needs regeneration
4. ✅ Regenerate in Xcode (uncheck/check automatic signing)
5. ✅ Clean rebuild
6. ✅ Delete and reinstall app

**The key is regenerating the provisioning profile - it will automatically include Live Activities from your entitlements file!**


