# Enable reCAPTCHA Enterprise and Add Keys

Now that we've added the reCAPTCHA Enterprise SDK to the app, we need to:

1. **Re-enable reCAPTCHA Enterprise** in Firebase Console
2. **Create/add iOS reCAPTCHA Enterprise key** in Google Cloud Console
3. **Create/add Android reCAPTCHA Enterprise key** (optional, for Android support)

---

## Step 1: Create reCAPTCHA Enterprise Keys in Google Cloud Console

### For iOS:

1. **Go to Google Cloud Console:**
   - [Google Cloud Console](https://console.cloud.google.com)
   - Select project: **botleji**
   - Navigate to **Security** → **reCAPTCHA Enterprise** → **Keys**

2. **Create New Key:**
   - Click **"Create Key"** or **"+"** button
   - **Key name:** `Bottleji iOS reCAPTCHA Enterprise`
   - **Platform:** Select **"iOS"**
   - Click **"Create"**

3. **Copy the Site Key:**
   - After creation, you'll see the key details
   - **Copy the Site Key** (it looks like: `6Lc...` or similar)
   - Save it for later (you'll need it if manual initialization is required)

### For Android (Optional):

1. **Create Another Key:**
   - Click **"Create Key"** again
   - **Key name:** `Bottleji Android reCAPTCHA Enterprise`
   - **Platform:** Select **"Android"**
   - **Package name:** `com.example.botleji` (your Android package name)
   - Click **"Create"**

2. **Copy the Site Key:**
   - Copy the Android Site Key as well

---

## Step 2: Enable reCAPTCHA Enterprise in Firebase Console

1. **Go to Firebase Console:**
   - [Firebase Console](https://console.firebase.google.com)
   - Select project: **botleji**
   - Navigate to **Authentication** → **Sign-in method**

2. **Enable Phone Sign-in:**
   - Click on **"Phone"** provider
   - Make sure it's **enabled** (toggle ON)

3. **Enable reCAPTCHA Enterprise:**
   - Look for **"App verification"** section
   - Find **"reCAPTCHA Enterprise"** option
   - **Enable/turn ON** reCAPTCHA Enterprise
   - Click **"Save"**

4. **Wait 2-3 minutes** for changes to propagate

---

## Step 3: Verify Keys Are Linked

The reCAPTCHA Enterprise keys you created in Google Cloud Console should automatically be linked to Firebase. Firebase will use them when needed.

---

## Step 4: Rebuild and Test

1. **Rebuild the app:**
   ```bash
   cd botleji
   flutter clean
   flutter run
   ```

2. **Test phone authentication:**
   - Enter phone number
   - Tap "Send Code"
   - The error should be gone
   - Phone auth should work

---

## Important Notes

- **iOS SDK is installed:** ✅ `RecaptchaEnterprise` pod is in Podfile
- **Android:** If you want Android support, you'll need to add the Android SDK too (separate step)
- **Automatic Detection:** Firebase Auth should automatically detect and use the Enterprise SDK
- **No Manual Initialization:** You don't need to manually initialize reCAPTCHA for Firebase Phone Auth

---

## For Android (Future Step)

If you want Android support too:

1. Add Android reCAPTCHA Enterprise SDK to `android/app/build.gradle`
2. Create Android key in Google Cloud Console (as shown above)
3. Firebase will automatically use it

For now, let's focus on iOS since that's where the error is occurring.

---

## Summary

✅ **What to do:**
1. Create iOS reCAPTCHA Enterprise key in Google Cloud Console
2. Enable reCAPTCHA Enterprise in Firebase Console → Authentication → Sign-in method → Phone
3. Rebuild and test

The SDK is already installed, so once you enable it and add the key, it should work! 🎯

