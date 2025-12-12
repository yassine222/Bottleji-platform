# Fix "Untrusted Developer" Issue on iOS

## Problem
You see "Untrusted Developer" message every time you reinstall the app, even though you're enrolled in Apple Developer Program.

## Solution

### Step 1: Trust Developer on Device

**On your iPhone/iPad:**

1. **Settings** → **General**
2. Scroll down to **"VPN & Device Management"** (or **"Profiles & Device Management"**)
3. Find your developer certificate:
   - Look for **"Developer App"**
   - Or your name/team: **"Yassine Romdhane"** / **"LXP2TU6LL6"**
4. **Tap** on it
5. Tap **"Trust [Your Name]"**
6. Tap **"Trust"** again to confirm

**Note:** This is a one-time action per device. The certificate should remain trusted.

---

### Step 2: Verify Xcode Signing

**In Xcode:**

1. Open `Runner.xcworkspace`
2. Select **Runner** project → **Runner** target
3. Go to **"Signing & Capabilities"** tab
4. Verify:
   - ✅ **"Automatically manage signing"** is checked
   - ✅ **Team** is selected: **"Yassine Romdhane (LXP2TU6LL6)"**
   - ✅ **Bundle Identifier:** `com.example.botleji`
   - ✅ **Provisioning Profile** shows as valid (not expired)

---

### Step 3: Sign In to Xcode with Your Apple ID

**Make sure Xcode is signed in:**

1. **Xcode** → **Settings** (or **Preferences**)
2. Click **"Accounts"** tab
3. Check if your Apple Developer account is listed
4. If not, click **"+"** and add your Apple ID
5. Select your account and click **"Download Manual Profiles"**

---

### Step 4: Register Your Device

**In Xcode:**

1. Connect your iPhone/iPad via USB
2. **Window** → **Devices and Simulators**
3. Your device should appear
4. If you see errors, Xcode should automatically register it

**Or manually in Apple Developer Portal:**

1. Go to: https://developer.apple.com/account/resources/devices/list
2. Click **"+"** to register device
3. Enter device name and UDID
4. Get UDID from Xcode: **Devices and Simulators** → Select device → Copy Identifier

---

### Step 5: Clean and Rebuild

**After trusting the certificate:**

```bash
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
flutter clean
flutter pub get
flutter run
```

---

## Why This Happens

**"Untrusted Developer" appears because:**
- iOS requires you to manually trust development certificates
- This is a security feature to prevent malicious apps
- You need to trust it **once per device**
- After trusting, it should persist (unless you revoke certificates)

---

## If Still Not Working

### Option 1: Revoke and Recreate Certificates

1. **Apple Developer Portal:** https://developer.apple.com/account/resources/certificates/list
2. Find your **iOS App Development** certificate
3. Click **"Revoke"**
4. In Xcode, clean build folder: **Product** → **Clean Build Folder**
5. Build again - Xcode will create a new certificate

### Option 2: Check Provisioning Profile

1. **Apple Developer Portal:** https://developer.apple.com/account/resources/profiles/list
2. Verify you have a valid **Development** profile for `com.example.botleji`
3. Make sure your device is registered in the profile

### Option 3: Re-sign in Xcode

1. **Xcode** → **Settings** → **Accounts**
2. Remove your account
3. Add it back
4. Click **"Download Manual Profiles"**

---

## Prevention

**To avoid this in the future:**
- ✅ Always trust the certificate when prompted
- ✅ Don't revoke certificates unnecessarily
- ✅ Keep your device registered in Apple Developer Portal
- ✅ Use automatic signing in Xcode

---

## Quick Checklist

- [ ] Trusted developer certificate on device (Settings → General → VPN & Device Management)
- [ ] Xcode signed in with Apple Developer account
- [ ] Automatic signing enabled in Xcode
- [ ] Team selected in Xcode (LXP2TU6LL6)
- [ ] Device registered in Xcode/Apple Developer Portal
- [ ] Clean rebuild after changes

---

## Important Notes

- **You must trust the certificate ONCE per device**
- After trusting, reinstalling the app should not ask again (unless certificates change)
- This is different from App Store apps (they're automatically trusted)
- Development builds require manual trust for security

---

If you've done all these steps and still see the issue, it might be:
- Certificate was revoked/changed
- Device not properly registered
- Multiple developer accounts causing confusion

Try revoking and recreating certificates as a last resort.


