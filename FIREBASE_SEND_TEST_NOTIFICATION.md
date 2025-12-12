# How to Send Test Push Notification from Firebase Console

## Step-by-Step Guide

### Step 1: Navigate to Cloud Messaging (Not Campaigns)

1. Go to: **https://console.firebase.google.com**
2. Select your project: **botleji**
3. In the left sidebar, look for **"Engage"** section
4. Click **"Cloud Messaging"** (NOT "Campaigns")

**Or direct link:**
**https://console.firebase.google.com/project/botleji/messaging**

---

### Step 2: Send Test Message

1. You'll see the Cloud Messaging page
2. Click **"Send your first message"** button (big blue button)
   - OR click **"New notification"** button (top right)

3. **Enter notification details:**
   - **Notification title:** "Test Notification"
   - **Notification text:** "Testing push notifications from Firebase"
   - Click **"Next"**

4. **Select target:**
   - Scroll down to **"Send test message"** section
   - Paste your FCM token: `clgTpw6u305IlWrZkCe5Qg:APA91bGXamZbX8E6HLypz54Vq5GMWnMLiD8R98XU3-jj7ZJ9y9JZ6Xnht8DYJU2tTS8xavyyS46OuTKJw0n4_xRb6FcxcCzSTHxFKdTBd4oHJecp-AsRZSc`
   - Click **"Test"**

5. **You should receive the notification on your device!** 🎉

---

## Correct Navigation Path

**Firebase Console → botleji → Engage → Cloud Messaging → Send test message**

**NOT:**
- ❌ Campaigns
- ❌ Notifications (old interface)

---

## Direct Links

- **Cloud Messaging:** https://console.firebase.google.com/project/botleji/messaging
- **Send Test:** https://console.firebase.google.com/project/botleji/messaging/compose

---

## Your FCM Token

**Current token:**
```
clgTpw6u305IlWrZkCe5Qg:APA91bGXamZbX8E6HLypz54Vq5GMWnMLiD8R98XU3-jj7ZJ9y9JZ6Xnht8DYJU2tTS8xavyyS46OuTKJw0n4_xRb6FcxcCzSTHxFKdTBd4oHJecp-AsRZSc
```

**Note:** This token is tied to your device. If you reinstall the app, you'll get a new token.

---

## Expected Result

After clicking "Test":
- ✅ Notification should appear on your iPhone
- ✅ Even if app is in background or closed
- ✅ Tapping it should open the app

---

## Troubleshooting

### Can't Find Cloud Messaging?

1. Make sure you're in the correct project: **botleji**
2. Look in left sidebar under **"Engage"** section
3. Click **"Cloud Messaging"** (not "Campaigns")

### Test Button Not Working?

- Make sure you pasted the full FCM token
- Token should start with: `clgTpw6u305...`
- Make sure your device has internet connection
- Make sure app is installed on device

---

**Go to Cloud Messaging section, not Campaigns!**


