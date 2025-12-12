# Fix: "reCAPTCHA SDK is not linked to your app" Error

## Problem
When trying to use Firebase Phone Auth, you get the error:
> "SMS verification failed - the reCAPTCHA SDK is not linked to your app"

## Root Causes

### 1. **reCAPTCHA Enterprise Settings in Firebase Console**
Firebase Console might have reCAPTCHA Enterprise enabled, which requires additional configuration.

### 2. **APNs Silent Push Not Working**
If silent push notifications fail, Firebase falls back to reCAPTCHA, but the SDK isn't properly linked.

### 3. **URL Scheme Not Properly Handled**
The reCAPTCHA redirect URL isn't being handled correctly by the app.

---

## Solutions

### Solution 1: Check Firebase Console Settings (MOST IMPORTANT)

1. **Go to Firebase Console:**
   - Navigate to [Firebase Console](https://console.firebase.google.com)
   - Select your project: **botleji**
   - Go to **Authentication** → **Sign-in method**
   - Click on **"Phone"** provider

2. **Check App Verification Settings:**
   - Look for **"App verification"** or **"reCAPTCHA Enterprise"** section
   - If **reCAPTCHA Enterprise** is enabled, you have two options:

   **Option A: Disable reCAPTCHA Enterprise (Recommended)**
   - Disable **reCAPTCHA Enterprise**
   - This will use the standard reCAPTCHA (built into Firebase SDK)
   - Wait a few minutes for changes to propagate

   **Option B: Keep reCAPTCHA Enterprise Enabled**
   - If you want to keep it enabled, you need to configure it properly
   - This requires additional setup in Google Cloud Console

3. **Verify APNs Configuration:**
   - Go to **Project Settings** → **Cloud Messaging** tab
   - Ensure your APNs Authentication Key (`.p8`) is uploaded
   - This allows silent push notifications to work (avoiding reCAPTCHA)

---

### Solution 2: Verify Encoded App ID

The Encoded App ID in `Info.plist` must match Firebase Console:

1. **Get Encoded App ID from Firebase Console:**
   - Go to **Project Settings** → **General** tab
   - Find your iOS app (`com.example.botleji`)
   - Look for **"Encoded App ID"** or **"App ID"** (it looks like: `app-1-XXXXX-ios-XXXXX`)

2. **Verify in `Info.plist`:**
   - Open `botleji/ios/Runner/Info.plist`
   - Check that `CFBundleURLSchemes` contains the correct Encoded App ID
   - Current value: `app-1-414913880297-ios-4621c0674928dcfb8a9078`
   - If it doesn't match Firebase Console, update it

---

### Solution 3: Ensure APNs Silent Push Works

Silent push notifications should work to avoid reCAPTCHA:

1. **Check Background App Refresh:**
   - On your iPhone: **Settings** → **General** → **Background App Refresh**
   - Ensure it's enabled for your app

2. **Test on Physical Device:**
   - Silent push notifications **only work on physical devices**
   - Simulators will always use reCAPTCHA (this is normal)

3. **Verify APNs Token Registration:**
   - Check that `setAPNSToken()` is called in `AppDelegate.swift`
   - This should happen automatically when the app registers for push notifications

---

### Solution 4: Check API Key Restrictions

If your Firebase API key has restrictions, it might block reCAPTCHA:

1. **Go to Google Cloud Console:**
   - Navigate to [Google Cloud Console](https://console.cloud.google.com/)
   - Select your project: **botleji**
   - Go to **APIs & Services** → **Credentials**

2. **Check API Key Restrictions:**
   - Find your Firebase API key
   - Check **"Application restrictions"**:
     - Should be **"None"** or allow your bundle ID
   - Check **"API restrictions"**:
     - Should allow **"Firebase Authentication API"** and **"reCAPTCHA Enterprise API"** (if using Enterprise)

---

### Solution 5: Clean and Rebuild

After making changes:

```bash
cd botleji
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
flutter run
```

---

## Quick Checklist

- [ ] **reCAPTCHA Enterprise disabled** in Firebase Console (or properly configured)
- [ ] **APNs key uploaded** to Firebase Console
- [ ] **Encoded App ID matches** between Firebase Console and `Info.plist`
- [ ] **Background App Refresh enabled** on device
- [ ] **Testing on physical device** (not simulator)
- [ ] **API key restrictions** allow Firebase Auth
- [ ] **AppDelegate handles URLs** correctly (already done ✅)

---

## Expected Behavior

### ✅ **Success (Silent Push):**
1. User enters phone number
2. App calls `verifyPhoneNumber()`
3. Firebase sends **silent push notification**
4. App receives notification → Firebase verifies app
5. **No reCAPTCHA shown** → SMS sent directly
6. User enters OTP → Success

### ⚠️ **Fallback (reCAPTCHA):**
1. User enters phone number
2. App calls `verifyPhoneNumber()`
3. Silent push fails (or simulator)
4. Firebase shows **reCAPTCHA challenge**
5. User completes reCAPTCHA
6. SMS sent → User enters OTP → Success

---

## If Still Not Working

1. **Check Firebase Console Logs:**
   - Go to **Authentication** → **Users** tab
   - Look for any error messages

2. **Check Xcode Console:**
   - Look for Firebase Auth error messages
   - Check if `canHandleURL()` is being called

3. **Verify Phone Sign-in is Enabled:**
   - Firebase Console → **Authentication** → **Sign-in method**
   - Ensure **"Phone"** is enabled

4. **Try Disabling and Re-enabling:**
   - Disable Phone sign-in in Firebase Console
   - Wait 1 minute
   - Re-enable Phone sign-in
   - This can reset configurations

---

## Most Common Fix

**90% of the time, the issue is:**
1. **reCAPTCHA Enterprise is enabled** in Firebase Console
2. **Solution:** Disable it in Firebase Console → Authentication → Sign-in method → Phone → App verification

Try this first! 🎯

