# iOS Push Notifications - Quick Start Guide

## 🎯 What You Need to Do (3 Steps)

### Step 1: Create APNs Auth Key (5 minutes)

1. Go to: **https://developer.apple.com/account/resources/authkeys/list**
2. Click **"+"** → Name: `Bottleji APNs Key` → Check **"APNs"** → **Register**
3. **Download** `.p8` file (⚠️ **ONLY ONCE!**)
4. **Note:** Key ID and Team ID

**Save securely:**
- `.p8` file
- Key ID (10 chars)
- Team ID (10 chars)

---

### Step 2: Upload to Firebase (2 minutes)

1. Go to: **https://console.firebase.google.com/project/botleji/settings/cloudmessaging**
2. Scroll to **"Apple app configuration"**
3. Click **"Upload"** → Select `.p8` file
4. Enter **Key ID** and **Team ID**
5. Click **"Upload"**

✅ Done!

---

### Step 3: Enable in Xcode (3 minutes)

1. Open: `botleji/ios/Runner.xcworkspace`
2. Select **Runner** project → **Runner** target
3. **"Signing & Capabilities"** tab
4. Click **"+ Capability"** → Add **"Push Notifications"**
5. Click **"+ Capability"** → Add **"Background Modes"** → Check **"Remote notifications"**
6. Enable **"Automatically manage signing"** → Select your **Team**

✅ Done!

---

## 🧪 Test It

1. **Run on physical device** (simulator won't work!)
2. **Grant notification permission** in app
3. **Check logs** for:
   ```
   🔔 FCMService: APNS Token: [token]
   🔔 FCMService: FCM Token: [token]
   ```
4. **Send test notification** from Firebase Console

---

## ⚠️ Important Notes

- ✅ Use **APNs Auth Key** (.p8) - NOT SSL certificates
- ✅ **Physical device required** - simulator doesn't support push notifications
- ✅ **Save `.p8` file securely** - you can only download once!
- ✅ **Never commit `.p8` to git**

---

## 🔗 Quick Links

- **Create APNs Key:** https://developer.apple.com/account/resources/authkeys/list
- **Firebase Console:** https://console.firebase.google.com/project/botleji/settings/cloudmessaging
- **Send Test:** https://console.firebase.google.com/project/botleji/notification

---

## 📋 Checklist

- [ ] APNs Auth Key created and downloaded
- [ ] Key ID and Team ID noted
- [ ] APNs key uploaded to Firebase
- [ ] Push Notifications capability added in Xcode
- [ ] Background Modes → Remote notifications enabled
- [ ] Automatic signing enabled with Team selected
- [ ] App tested on physical device
- [ ] FCM token generated
- [ ] Test notification received

---

**For detailed instructions, see:** `IOS_PUSH_NOTIFICATIONS_SETUP.md`

