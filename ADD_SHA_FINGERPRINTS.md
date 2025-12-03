# Adding SHA Fingerprints to Firebase Console

## Your SHA Fingerprints

From your Android debug keystore:

### SHA-1 Fingerprint:
```
38:BD:76:A0:B6:89:39:D2:DF:B3:D0:FA:46:27:F9:97:A7:42:03:2A
```

### SHA-256 Fingerprint:
```
99:ED:27:78:47:B8:26:A0:93:E8:D0:53:10:4E:61:C5:D3:6B:DB:E0:0E:D2:A9:2A:30:AD:84:E6:40:F3:23:04
```

---

## Step-by-Step: Add to Firebase Console

### Step 1: Open Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **botleji**

### Step 2: Navigate to Project Settings

1. Click the **⚙️ gear icon** next to "Project Overview" (top left)
2. Select **"Project settings"**

### Step 3: Find Your Android App

1. Scroll down to the **"Your apps"** section
2. Find your Android app with package name: `com.example.botleji`
3. Click on the app card to expand it

### Step 4: Add SHA-1 Fingerprint

1. In the app details, find the **"SHA certificate fingerprints"** section
2. Click **"Add fingerprint"** button
3. Paste your SHA-1 fingerprint:
   ```
   38:BD:76:A0:B6:89:39:D2:DF:B3:D0:FA:46:27:F9:97:A7:42:03:2A
   ```
4. Click **"Save"**

### Step 5: Add SHA-256 Fingerprint

1. Click **"Add fingerprint"** again
2. Paste your SHA-256 fingerprint:
   ```
   99:ED:27:78:47:B8:26:A0:93:E8:D0:53:10:4E:61:C5:D3:6B:DB:E0:0E:D2:A9:2A:30:AD:84:E6:40:F3:23:04
   ```
3. Click **"Save"**

---

## Verification

After adding both fingerprints, you should see:

```
SHA certificate fingerprints
✓ 38:BD:76:A0:B6:89:39:D2:DF:B3:D0:FA:46:27:F9:97:A7:42:03:2A
✓ 99:ED:27:78:47:B8:26:A0:93:E8:D0:53:10:4E:61:C5:D3:6B:DB:E0:0E:D2:A9:2A:30:AD:84:E6:40:F3:23:04
```

---

## Direct Link

You can also use this direct link to go straight to your app settings:

**Firebase Console - Project Settings:**
https://console.firebase.google.com/project/botleji/settings/general

Then scroll down to "Your apps" → Android app → Add fingerprint

---

## Important Notes

### Debug vs Release Keystores

⚠️ **Current fingerprints are from DEBUG keystore**

These fingerprints are from your debug keystore (`~/.android/debug.keystore`), which is fine for:
- ✅ Development and testing
- ✅ Firebase Phone Auth testing
- ✅ FCM testing

For **production release**, you'll need to:
1. Create a release keystore
2. Get SHA fingerprints from the release keystore
3. Add those fingerprints to Firebase as well

### When to Add Release Fingerprints

Add release keystore fingerprints when:
- You're ready to publish to Google Play Store
- You want to test production builds
- You're using a different keystore for release builds

---

## Next Steps

After adding the fingerprints:

1. ✅ **Firebase Phone Auth** will work without reCAPTCHA (in most cases)
2. ✅ **FCM** will work properly
3. ✅ **Google Sign-In** will work (if you enable it later)

### Test Phone Auth

1. Run your app on an Android device
2. Try to verify a phone number
3. You should receive an SMS code without reCAPTCHA (or with minimal reCAPTCHA)

---

## Troubleshooting

### Fingerprint Not Showing Up

- Wait a few minutes - Firebase may take time to sync
- Refresh the page
- Verify you're looking at the correct app (check package name)

### Still Seeing reCAPTCHA

- Ensure fingerprints are added correctly (no extra spaces)
- Try on a physical device (emulator may always show reCAPTCHA)
- Check that you're using the same keystore that generated the fingerprints
- Wait 5-10 minutes for Firebase to propagate changes

### Need Release Keystore Fingerprints

If you have a release keystore, get its fingerprints:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
```

Then add those fingerprints to Firebase as well.

---

## Quick Copy-Paste

**SHA-1:**
```
38:BD:76:A0:B6:89:39:D2:DF:B3:D0:FA:46:27:F9:97:A7:42:03:2A
```

**SHA-256:**
```
99:ED:27:78:47:B8:26:A0:93:E8:D0:53:10:4E:61:C5:D3:6B:DB:E0:0E:D2:A9:2A:30:AD:84:E6:40:F3:23:04
```

---

## Done! 🎉

Once you've added both fingerprints to Firebase Console, Firebase Phone Auth should work smoothly!



