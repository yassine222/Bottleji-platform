# Troubleshooting: reCAPTCHA SDK Error Still Persists

If you're still seeing the error after deleting the reCAPTCHA Enterprise key, try these steps:

## Step 1: Verify Key Was Deleted

1. **Go to Google Cloud Console:**
   - [Google Cloud Console](https://console.cloud.google.com)
   - Security → reCAPTCHA Enterprise → Keys
   - **Verify the key is actually deleted** (should not appear in the list)

2. **Wait Longer:**
   - Changes can take **10-15 minutes** to fully propagate
   - Firebase caches settings, so it might take time

## Step 2: Check Firebase Console Settings

1. **Go to Firebase Console:**
   - [Firebase Console](https://console.firebase.google.com)
   - Authentication → Sign-in method → Phone

2. **Check for any reCAPTCHA settings:**
   - Look for "App verification" section
   - Check if there's a "reCAPTCHA Enterprise" option (even if disabled)
   - If you see it, try toggling it OFF and ON, then OFF again

## Step 3: Verify URL Scheme Matches Firebase Console

The URL scheme in `Info.plist` must match Firebase Console:

1. **Get Encoded App ID from Firebase Console:**
   - Firebase Console → Project Settings → General
   - Find your iOS app (`com.example.botleji`)
   - Look for **"Encoded App ID"** or **"App ID"**
   - It should look like: `app-1-XXXXX-ios-XXXXX`

2. **Verify in `Info.plist`:**
   - Current value: `app-1-414913880297-ios-4621c0674928dcfb8a9078`
   - If it doesn't match Firebase Console, **update it**

3. **After updating, rebuild:**
   ```bash
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter pub get
   flutter run
   ```

## Step 4: Check API Key Restrictions

The Firebase API key might have restrictions blocking reCAPTCHA:

1. **Go to Google Cloud Console:**
   - [Google Cloud Console](https://console.cloud.google.com)
   - APIs & Services → Credentials

2. **Find your Firebase API key:**
   - Look for keys associated with your Firebase project
   - Usually named something like "Browser key" or "iOS key"

3. **Check restrictions:**
   - Click on the API key
   - Check **"Application restrictions"**:
     - Should be **"None"** or allow your bundle ID
   - Check **"API restrictions"**:
     - Should allow **"Firebase Authentication API"**
     - Should **NOT** restrict reCAPTCHA APIs

4. **If restricted, either:**
   - Remove restrictions (for development)
   - Or add **"reCAPTCHA Enterprise API"** to allowed APIs

## Step 5: Disable and Re-enable Phone Sign-in

Sometimes toggling Phone sign-in can reset configurations:

1. **Firebase Console:**
   - Authentication → Sign-in method → Phone
   - **Disable** Phone sign-in
   - Click **Save**
   - Wait 1 minute
   - **Enable** Phone sign-in again
   - Click **Save**

2. **Wait 2-3 minutes** for changes to propagate

3. **Test again**

## Step 6: Check for Multiple reCAPTCHA Keys

There might be multiple keys, and you deleted the wrong one:

1. **Google Cloud Console:**
   - Security → reCAPTCHA Enterprise → Keys
   - Check if there are **other reCAPTCHA keys**:
     - Web keys
     - Android keys
     - Other iOS keys

2. **Delete ALL iOS reCAPTCHA Enterprise keys:**
   - If you see multiple iOS keys, delete all of them
   - Only keep standard reCAPTCHA keys (if any)

## Step 7: Verify Firebase Project Settings

1. **Firebase Console:**
   - Project Settings → General
   - Check your iOS app configuration
   - Verify Bundle ID: `com.example.botleji`

2. **Check Cloud Messaging:**
   - Project Settings → Cloud Messaging
   - Verify APNs key is uploaded
   - This is required for silent push notifications

## Step 8: Clean Build and Reinstall

Sometimes cached configurations cause issues:

```bash
# Complete clean
cd botleji
flutter clean
cd ios
rm -rf Pods Podfile.lock .symlinks
cd ..
flutter pub get
cd ios
pod install
cd ..
flutter run
```

## Step 9: Check Firebase Console Logs

1. **Firebase Console:**
   - Go to **Authentication** → **Users** tab
   - Look for any error messages or failed attempts
   - This can give clues about what's wrong

## Step 10: Alternative: Use Test Phone Numbers

While troubleshooting, you can use Firebase test phone numbers:

1. **Firebase Console:**
   - Authentication → Sign-in method → Phone
   - Scroll to **"Phone numbers for testing"**
   - Add a test phone number (e.g., `+1 650-555-3434`)
   - Set a test verification code (e.g., `123456`)

2. **Test with this number:**
   - Use the test phone number in your app
   - Enter the test verification code
   - This bypasses reCAPTCHA entirely

## Step 11: Check if reCAPTCHA Enterprise API is Enabled

Even if the key is deleted, the API might still be enabled:

1. **Google Cloud Console:**
   - APIs & Services → Enabled APIs
   - Search for **"reCAPTCHA Enterprise API"**
   - If it's enabled, you can **disable it** (but this might affect other services)

## Step 12: Contact Firebase Support

If nothing works:

1. **Firebase Console:**
   - Click the **"?"** icon (Help)
   - Select **"Contact support"**
   - Explain the issue: "reCAPTCHA SDK is not linked" error persists after deleting Enterprise key

## Most Likely Causes

1. **Key deletion hasn't propagated yet** (wait 10-15 minutes)
2. **URL scheme mismatch** (check Step 3)
3. **API key restrictions** (check Step 4)
4. **Multiple keys exist** (check Step 6)

## Quick Test

Try this quick test to see if it's a propagation issue:

1. **Wait 15 minutes** after deleting the key
2. **Completely close and restart the app**
3. **Try phone authentication again**

If it still doesn't work, go through the steps above systematically.

