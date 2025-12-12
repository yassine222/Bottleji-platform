# How to Disable reCAPTCHA Enterprise in Firebase Console

## The Error
```
SMS verification failed: The reCAPTCHA SDK is not linked to your app. 
See https://cloud.google.com/recaptcha-enterprise/docs/instrument-ios-apps
```

This error means **reCAPTCHA Enterprise is enabled** in Firebase Console, but it's not properly configured.

## Solution: Disable reCAPTCHA Enterprise

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project: **botleji**

### Step 2: Navigate to Phone Authentication Settings
1. Click **"Authentication"** in the left sidebar
2. Click **"Sign-in method"** tab
3. Find **"Phone"** in the providers list
4. Click on **"Phone"** (or the edit icon)

### Step 3: Find App Verification Settings
1. Look for **"App verification"** section
2. You should see options like:
   - **"reCAPTCHA Enterprise"** (might be enabled)
   - **"App check"** (optional)
   - **"SafetyNet"** (Android only)

### Step 4: Disable reCAPTCHA Enterprise
1. If you see **"reCAPTCHA Enterprise"** toggle or checkbox:
   - **Turn it OFF** or **Uncheck it**
2. Click **"Save"** at the bottom
3. Wait 1-2 minutes for changes to propagate

### Step 5: Verify Settings
After disabling, the app should use **standard reCAPTCHA** (built into Firebase SDK), which works automatically with `FirebaseAppDelegateProxyEnabled = true`.

---

## If You Can't Find the Option

### Option A: It's Already Disabled
- If you don't see "reCAPTCHA Enterprise" option, it might already be disabled
- The error might be from a different cause

### Option B: Check Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select project: **botleji**
3. Navigate to **"APIs & Services"** → **"Enabled APIs"**
4. Look for **"reCAPTCHA Enterprise API"**
5. If it's enabled, you can disable it (but this might affect other services)

---

## Alternative: Keep reCAPTCHA Enterprise Enabled

If you want to keep reCAPTCHA Enterprise enabled, you need to:

1. **Install reCAPTCHA Enterprise SDK** (complex, not recommended for Flutter)
2. **Configure it in your app** (requires native iOS code)
3. **Link it properly** (follows the Google Cloud documentation)

**Recommendation:** Just disable it. The standard reCAPTCHA works perfectly for most apps.

---

## After Disabling

1. **Rebuild your app:**
   ```bash
   flutter clean
   flutter run
   ```

2. **Test phone authentication:**
   - Enter phone number
   - Should work without the error
   - Firebase will use standard reCAPTCHA automatically

---

## Why This Happens

- **reCAPTCHA Enterprise** is a premium feature that requires additional SDK setup
- **Standard reCAPTCHA** is built into Firebase Auth SDK (works automatically)
- When Enterprise is enabled but not configured, you get this error
- Disabling Enterprise uses the standard version (which is what we want)

---

## Quick Checklist

- [ ] Go to Firebase Console → Authentication → Sign-in method → Phone
- [ ] Find "App verification" or "reCAPTCHA Enterprise" section
- [ ] Disable/turn off reCAPTCHA Enterprise
- [ ] Click Save
- [ ] Wait 1-2 minutes
- [ ] Rebuild and test app

---

## Still Not Working?

If you still get the error after disabling:

1. **Check URL scheme in Info.plist:**
   - Should have: `app-1-414913880297-ios-4621c0674928dcfb8a9078`
   - Verify it matches Firebase Console → Project Settings → General → iOS App

2. **Verify FirebaseAppDelegateProxyEnabled:**
   - Should be `true` in `Info.plist`
   - We already set this ✅

3. **Check APNs configuration:**
   - Firebase Console → Project Settings → Cloud Messaging
   - Ensure APNs key is uploaded

4. **Try on physical device:**
   - Simulators might have issues
   - Physical device is recommended

