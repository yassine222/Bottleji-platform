# Integrate reCAPTCHA Enterprise SDK for Firebase Phone Auth

## Current Situation

Firebase Console has reCAPTCHA Enterprise enabled, but the SDK is not linked to the app, causing the error:
> "The reCAPTCHA SDK is not linked to your app"

## Solution: Add reCAPTCHA Enterprise SDK

We need to add the reCAPTCHA Enterprise SDK to the iOS project so Firebase can use it.

## Step 1: Get reCAPTCHA Site Key from Firebase Console

1. **Go to Firebase Console:**
   - [Firebase Console](https://console.firebase.google.com)
   - Select project: **botleji**
   - Go to **Authentication** → **Sign-in method** → **Phone**

2. **Find the reCAPTCHA Site Key:**
   - Look for **"App verification"** section
   - Find **"reCAPTCHA Enterprise"** settings
   - Copy the **Site Key** (it looks like: `6Lc...` or similar)

3. **Alternative: Get from Google Cloud Console:**
   - [Google Cloud Console](https://console.cloud.google.com)
   - Security → reCAPTCHA Enterprise → Keys
   - Find your iOS reCAPTCHA key
   - Copy the **Site Key**

## Step 2: Add SDK to Podfile

✅ **Already done** - Added `pod 'RecaptchaEnterprise', '~> 18.8'` to Podfile

## Step 3: Install Pods

```bash
cd botleji/ios
pod install
cd ../..
```

## Step 4: Initialize reCAPTCHA in AppDelegate

We need to initialize reCAPTCHA Enterprise SDK in `AppDelegate.swift` using the site key.

**Note:** For Firebase Phone Auth, Firebase should automatically detect and use the SDK. However, if you need to manually initialize it, you would do it in AppDelegate.

## Step 5: Verify Integration

After installing pods and rebuilding:

1. **Check if SDK is linked:**
   - Build the app
   - Check for any linking errors

2. **Test phone authentication:**
   - The error should be gone
   - Phone auth should work

## Important Notes

- **Firebase Phone Auth** should automatically use reCAPTCHA Enterprise SDK if it's installed
- You **don't need to manually call** `initializeRecaptchaConfig()` for Firebase Phone Auth
- Firebase Auth SDK will automatically detect and use the Enterprise SDK
- The SDK is initialized automatically when Firebase Auth is initialized

## If You Don't Have the Site Key

If you can't find the site key in Firebase Console:

1. **Create a new reCAPTCHA Enterprise key:**
   - Google Cloud Console → Security → reCAPTCHA Enterprise → Keys
   - Click **"Create Key"**
   - Select **"iOS"** platform
   - Copy the **Site Key**

2. **Or disable reCAPTCHA Enterprise:**
   - This is the simpler option
   - Firebase will use standard reCAPTCHA (built-in)

## Next Steps

1. Get the reCAPTCHA Site Key from Firebase/Google Cloud Console
2. Run `pod install` to install the SDK
3. Rebuild the app
4. Test phone authentication

The SDK should now be properly linked! 🎯

