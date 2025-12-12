# Create App ID in Apple Developer Portal

## Step-by-Step Guide

### Step 1: Go to Identifiers

1. Go to: **https://developer.apple.com/account/resources/identifiers/list**
2. Click the **"+"** button (top left, next to "Identifiers")

---

### Step 2: Select App ID Type

1. Select **"App IDs"** (it should be selected by default)
2. Click **"Continue"**

---

### Step 3: Select Type

1. Select **"App"** (first option)
2. Click **"Continue"**

---

### Step 4: Register Your App ID

Fill in the form:

#### Description:
```
Bottleji - Bottle Collection App
```

Or you can use:
```
Bottleji iOS App
```

**This is just a description for you to identify it later. It doesn't affect functionality.**

---

#### Bundle ID:

**Select: "Explicit"**

**Enter:** `com.example.botleji`

⚠️ **Important:** This MUST match exactly what's in your Xcode project!

---

### Step 5: Select Capabilities

**Scroll down and check these capabilities:**

✅ **Push Notifications** ⭐ **CRITICAL - MUST CHECK THIS!**

✅ **Sign In with Apple** (if you're using it)

✅ **Associated Domains** (if you're using deep links)

✅ **Background Modes** (if needed - usually auto-enabled with Push Notifications)

**Other capabilities (check if you use them):**
- ✅ **Live Activities** (you're using this, so check it!)
- ✅ **Associated Domains**
- ✅ **Background Modes**
- ✅ **App Groups** (if sharing data between app and widgets)

---

### Step 6: Register

1. Review your selections:
   - **Description:** Bottleji - Bottle Collection App
   - **Bundle ID:** com.example.botleji
   - **Capabilities:** Push Notifications, Live Activities, etc.

2. Click **"Register"**

3. You should see: **"Your App ID has been registered."**

---

### Step 7: Verify

1. Go back to: **https://developer.apple.com/account/resources/identifiers/list**
2. Search for: `com.example.botleji`
3. Click on it
4. Verify:
   - ✅ **Push Notifications** is enabled
   - ✅ **Live Activities** is enabled (if you checked it)
   - ✅ Other capabilities you selected

---

### Step 8: Update Xcode

After creating the App ID:

1. Open `Runner.xcworkspace` in Xcode
2. **Runner** project → **Runner** target
3. **Signing & Capabilities** tab
4. **Uncheck** "Automatically manage signing"
5. **Check** "Automatically manage signing" again
6. Select **Team**: "Yassine Romdhane (LXP2TU6LL6)"
7. Xcode will now use the App ID you just created
8. Wait for provisioning profile to be generated

---

### Step 9: Clean Rebuild

```bash
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
flutter clean
flutter run
```

---

## What You Need

### Description Examples:

**Option 1 (Recommended):**
```
Bottleji - Bottle Collection App
```

**Option 2 (Simple):**
```
Bottleji iOS App
```

**Option 3 (Detailed):**
```
Bottleji - Waste Management and Recycling App
```

**Any of these work!** It's just for your reference.

---

### Bundle ID (CRITICAL):

**Must be exactly:** `com.example.botleji`

This must match your Xcode project exactly!

---

### Required Capabilities:

✅ **Push Notifications** - **MUST CHECK!**

✅ **Live Activities** - You're using this, so check it!

✅ **Background Modes** - Usually auto-enabled, but check if available

---

## Quick Checklist

Before registering:
- [ ] Description ready (e.g., "Bottleji - Bottle Collection App")
- [ ] Bundle ID: `com.example.botleji`
- [ ] Push Notifications capability will be checked ✅
- [ ] Live Activities capability will be checked ✅

After registering:
- [ ] App ID created successfully
- [ ] Push Notifications enabled in App ID
- [ ] Xcode signing updated
- [ ] App rebuilt
- [ ] Test APNS token generation

---

## After Creating App ID

Once the App ID is created with Push Notifications enabled:

1. **Regenerate provisioning profile in Xcode** (uncheck/check automatic signing)
2. **Clean rebuild** the app
3. **Test again** - APNS token should now work!

---

## Important Notes

- **Description is just for your reference** - it doesn't affect functionality
- **Bundle ID must match Xcode exactly** - `com.example.botleji`
- **Push Notifications MUST be checked** - this is critical!
- **After creating, rebuild app** - Xcode needs to regenerate provisioning profile

---

**Ready? Go create your App ID now at:**
**https://developer.apple.com/account/resources/identifiers/list**

