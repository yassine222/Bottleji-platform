# Apple Developer Portal: Enable Live Activities Capability

## Capability Name: **"Live Activities"**

This capability corresponds to the entitlement: `com.apple.developer.usernotifications.live-activities`

---

## Steps to Enable:

### 1. Enable for Main App ID (`com.example.botleji`)

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click on your App ID: **com.example.botleji**
3. Scroll down to **"Capabilities"** section
4. Find and check ✅ **"Live Activities"**
   - It should be listed under Push Notifications or User Notifications section
   - Look for the exact text: **"Live Activities"**
5. Click **"Save"** or **"Continue"** → **"Save"**

### 2. Enable for Widget Extension App ID (`com.example.botleji.LiveActivityWidgetExtension`)

1. In the same portal, find your Widget Extension App ID
2. Click on: **com.example.botleji.LiveActivityWidgetExtension**
3. Scroll to **"Capabilities"** section
4. Find and check ✅ **"Live Activities"**
5. Click **"Save"**

### 3. Regenerate Provisioning Profiles

1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Find your provisioning profile: **"Bottleji App"** (for main app)
3. Click **"Edit"**
4. The App ID should show **"Live Activities"** as enabled
5. Click **"Generate"** (or **"Save"** if it regenerates automatically)
6. **Download** the new profile
7. Repeat for the Widget Extension provisioning profile (if you have a separate one)

### 4. Install New Profiles in Xcode

**Option A: Double-click to install**
- Double-click the downloaded `.mobileprovision` file(s)
- They will be installed automatically

**Option B: Manual install**
- Xcode → Preferences (Settings) → Accounts
- Select your Apple ID
- Click **"Download Manual Profiles"**
- Or drag-and-drop the `.mobileprovision` file into Xcode

### 5. Update Xcode Project

1. In Xcode, select **Runner** target
2. Go to **Signing & Capabilities**
3. In **"Provisioning Profile"** dropdown, select the newly downloaded profile
4. Repeat for **LiveActivityWidgetExtension** target

---

## Visual Guide:

In Apple Developer Portal, the capability looks like this:

```
Capabilities:
☑ Push Notifications
☑ App Groups
☑ Live Activities          ← Enable this one!
☐ Associated Domains
...
```

---

## Verification Checklist:

- [ ] ✅ Live Activities enabled for `com.example.botleji` App ID
- [ ] ✅ Live Activities enabled for `com.example.botleji.LiveActivityWidgetExtension` App ID
- [ ] ✅ Provisioning profiles regenerated
- [ ] ✅ New profiles downloaded
- [ ] ✅ Profiles installed in Xcode
- [ ] ✅ Xcode project updated to use new profiles
- [ ] ✅ Clean build folder and rebuild

---

## Notes:

- **Capability Name:** "Live Activities" (exact name in Apple Developer Portal)
- **Entitlement Key:** `com.apple.developer.usernotifications.live-activities`
- **Required for:** Both main app AND widget extension App IDs
- **After enabling:** Must regenerate provisioning profiles for changes to take effect


