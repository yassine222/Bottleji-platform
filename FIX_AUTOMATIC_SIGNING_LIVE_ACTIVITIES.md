# Fix: Automatic Signing Failed - Live Activities Entitlement

## Problem
Xcode automatic signing fails because provisioning profile doesn't include Live Activities entitlement.

## Solution Options

### Option 1: Temporarily Remove Live Activities (Quick Fix)

**To get the app building first, then add it back:**

1. **Edit `Runner.entitlements`:**
   - Comment out or temporarily remove the Live Activities line:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
   	<key>aps-environment</key>
   	<string>development</string>
   	<!-- Temporarily commented out to fix provisioning profile -->
   	<!-- <key>com.apple.developer.usernotifications.live-activities</key>
   	<true/> -->
   </dict>
   </plist>
   ```

2. **In Xcode:**
   - Uncheck/check "Automatically manage signing"
   - This should work now (without Live Activities)

3. **After app builds successfully:**
   - Add Live Activities back to entitlements
   - Try manual provisioning profile (Option 2)

---

### Option 2: Create Manual Provisioning Profile (Recommended)

**Create a provisioning profile that includes Live Activities:**

1. **Go to Apple Developer Portal:**
   - https://developer.apple.com/account/resources/profiles/list

2. **Click "+" to create new profile**

3. **Select:**
   - Type: **"iOS App Development"**
   - Click **Continue**

4. **Select App ID:**
   - Choose: `com.example.botleji`
   - Click **Continue**

5. **Select Certificate:**
   - Choose your development certificate
   - Click **Continue**

6. **Select Devices:**
   - Choose your test devices
   - Click **Continue**

7. **Profile Name:**
   - Enter: `Bottleji Development with Live Activities`
   - Click **Generate**

8. **Download the profile**

9. **In Xcode:**
   - **Signing & Capabilities** tab
   - **Uncheck** "Automatically manage signing"
   - Under **Provisioning Profile**, select **"Import Profile..."**
   - Select the downloaded `.mobileprovision` file
   - Select your **Team**

10. **Build again** - should work now!

---

### Option 3: Wait and Retry (Sometimes Works)

**Sometimes Apple's servers need time to sync:**

1. **Wait 5-10 minutes** after enabling Push Notifications in App ID
2. **In Xcode:**
   - Uncheck "Automatically manage signing"
   - Wait 30 seconds
   - Check "Automatically manage signing" again
   - Select Team
3. **Try building again**

---

### Option 4: Use Manual Signing Temporarily

**To get past the error:**

1. **In Xcode:**
   - **Signing & Capabilities** tab
   - **Uncheck** "Automatically manage signing"
   - Select **Team**
   - Under **Provisioning Profile**, select **"Download Profile"** or **"Import Profile"**
   - Or select an existing profile from the dropdown

2. **Build** - this might work with manual profile selection

---

## Recommended Approach

**Try in this order:**

1. **Option 1** (Temporarily remove Live Activities) - Get app building first
2. **Option 2** (Manual provisioning profile) - Add Live Activities back properly
3. **Option 3** (Wait and retry) - If you have time

---

## Why This Happens

**Xcode automatic signing sometimes doesn't include all entitlements** when:
- Entitlements are added after App ID is created
- Apple's servers haven't synced yet
- The provisioning profile was cached

**Manual provisioning profile gives you full control!**

---

## After Fixing

Once the app builds:
1. ✅ Test APNS token generation
2. ✅ If APNS works, you can add Live Activities back later
3. ✅ Or use manual provisioning profile for Live Activities

---

**I recommend Option 1 first (temporarily remove Live Activities) to get the app building, then we can add it back properly!**


