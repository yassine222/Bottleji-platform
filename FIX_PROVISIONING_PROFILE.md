# Fix Provisioning Profile for Live Activities Entitlement

You need to regenerate your provisioning profiles to include the Live Activities entitlement.

## Steps to Fix:

### 1. Apple Developer Portal - Main App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/identifiers/list)
2. Find your **App ID** (`com.example.botleji`)
3. Click on it to edit
4. **Enable "Live Activities"** capability
5. Click **Save**

### 2. Apple Developer Portal - Widget Extension App ID

1. In the same portal, find your **Widget Extension App ID** (`com.example.botleji.LiveActivityWidgetExtension`)
2. Click on it to edit
3. **Enable "Live Activities"** capability
4. Click **Save**

### 3. Regenerate Provisioning Profiles in Xcode

#### Option A: Automatic (Recommended)

1. Open your project in **Xcode**
2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"** if not already checked
5. Xcode will automatically regenerate profiles when you build
6. Do the same for **LiveActivityWidgetExtension** target

#### Option B: Manual (If automatic doesn't work)

1. In Xcode, select **Runner** target
2. Go to **Signing & Capabilities** tab
3. Click on the provisioning profile dropdown
4. Select **"Download Manual Profiles"**
5. Or go to Apple Developer Portal → **Certificates, Identifiers & Profiles**
6. Find your **"Bottleji App"** provisioning profile
7. Click **Edit**
8. Click **Generate** (this will regenerate with new entitlements)
9. Download the new profile
10. In Xcode, select **Download Profile** from the provisioning profile dropdown

### 4. Clean and Rebuild

After updating profiles:

```bash
cd botleji/ios
rm -rf ~/Library/Developer/Xcode/DerivedData/*
# Or in Xcode: Product → Clean Build Folder (Shift+Cmd+K)
```

Then rebuild in Xcode.

### 5. Verify

After rebuilding, the error should be gone. If it persists:

1. Make sure both App IDs have Live Activities enabled in the portal
2. Make sure you're using the **latest** provisioning profile
3. Try removing and re-adding the provisioning profile in Xcode

## Quick Checklist:

- [ ] Main App ID (`com.example.botleji`) has Live Activities enabled
- [ ] Widget Extension App ID (`com.example.botleji.LiveActivityWidgetExtension`) has Live Activities enabled
- [ ] Provisioning profiles regenerated
- [ ] Xcode project cleaned and rebuilt


