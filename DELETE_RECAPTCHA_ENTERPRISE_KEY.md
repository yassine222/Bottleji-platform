# How to Delete reCAPTCHA Enterprise Key from Google Cloud Console

## Why Delete the Key?

If you can't find a disable option in Firebase Console, deleting the reCAPTCHA Enterprise key from Google Cloud Console will effectively disable it. Firebase will then fall back to the standard reCAPTCHA (built into Firebase Auth SDK).

## Step-by-Step Instructions

### Step 1: Go to Google Cloud Console
1. Open [Google Cloud Console](https://console.cloud.google.com)
2. Make sure you're in the correct project: **botleji**
   - Check the project dropdown at the top

### Step 2: Navigate to reCAPTCHA Keys
1. In the search bar at the top, type: **"reCAPTCHA"**
2. Click on **"reCAPTCHA Enterprise"** or **"reCAPTCHA"** from the results
3. Or navigate manually:
   - Click **"Security"** in the left menu
   - Click **"reCAPTCHA Enterprise"**
   - Click **"Keys"** tab

### Step 3: Find Your reCAPTCHA Key
1. You'll see a list of reCAPTCHA keys
2. Look for keys that are:
   - **Platform:** iOS
   - **Type:** reCAPTCHA Enterprise
   - **Associated with:** Your Firebase project

### Step 4: Delete the Key
1. Find the reCAPTCHA Enterprise key you want to delete
2. Click on the **three dots (⋮)** or **menu icon** next to the key
3. Click **"Delete"** or **"Remove"**
4. Confirm the deletion

### Step 5: Wait for Propagation
1. Wait **2-5 minutes** for changes to propagate
2. Firebase will automatically detect that the key is deleted
3. Firebase will fall back to standard reCAPTCHA

### Step 6: Test Your App
1. Rebuild your app:
   ```bash
   flutter clean
   flutter run
   ```
2. Test phone authentication
3. The error should be gone!

---

## Alternative: Check Firebase Console First

Before deleting, double-check Firebase Console one more time:

1. **Firebase Console** → **Authentication** → **Sign-in method**
2. Click **"Phone"**
3. Look for:
   - **"App verification"** section
   - **"reCAPTCHA Enterprise"** toggle/checkbox
   - **"Settings"** or **"Advanced"** tab

If you still can't find it, proceed with deleting the key from Google Cloud Console.

---

## What Happens After Deletion?

✅ **Good:**
- reCAPTCHA Enterprise is disabled
- Firebase uses standard reCAPTCHA (built-in)
- Phone authentication works normally
- No additional SDK needed

⚠️ **Note:**
- The key is permanently deleted
- If you need it later, you'll need to create a new one
- But for most apps, you don't need reCAPTCHA Enterprise

---

## If You Have Multiple Keys

If you see multiple reCAPTCHA keys:

1. **Check the key details:**
   - Look at the **"Platform"** column
   - Look for **"iOS"** platform
   - Check if it's associated with your Firebase project

2. **Delete only the iOS reCAPTCHA Enterprise key:**
   - Don't delete Android keys (if you have them)
   - Don't delete web keys (if you have them)
   - Only delete the iOS Enterprise key

3. **If unsure:**
   - Check the key name/description
   - Look for keys created around the time you set up Firebase Phone Auth
   - You can also check Firebase Console → Project Settings → General → iOS App for clues

---

## Verification

After deleting the key:

1. **Wait 2-5 minutes**
2. **Go back to Firebase Console:**
   - Authentication → Sign-in method → Phone
   - The reCAPTCHA Enterprise option should be gone or disabled

3. **Test your app:**
   - The "reCAPTCHA SDK is not linked" error should disappear
   - Phone authentication should work

---

## Still Not Working?

If you still get the error after deleting the key:

1. **Wait longer** (up to 10 minutes for full propagation)
2. **Check Firebase Console** → **Authentication** → **Sign-in method** → **Phone**
3. **Verify `FirebaseAppDelegateProxyEnabled = true`** in `Info.plist` ✅ (already done)
4. **Check URL scheme** in `Info.plist` matches Firebase Console
5. **Rebuild app completely:**
   ```bash
   flutter clean
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter pub get
   flutter run
   ```

---

## Summary

✅ **Delete the reCAPTCHA Enterprise key from Google Cloud Console**
✅ **Wait 2-5 minutes for propagation**
✅ **Test phone authentication**
✅ **Error should be resolved!**

This is a valid and safe approach when you can't find the disable option in Firebase Console.

