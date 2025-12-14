# Quick Fix: Provisioning Profile for Live Activities

## Fastest Method (Xcode Automatic Signing):

1. **Open Xcode**
2. **Select Runner target** → Signing & Capabilities tab
3. **Enable "Automatically manage signing"** ✅
4. Select your **Team** (LXP2TU6LL6)
5. **Do the same for LiveActivityWidgetExtension target**
6. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
7. **Build again** - Xcode will automatically regenerate profiles

## If Automatic Signing Doesn't Work:

### Step 1: Enable Live Activities in Apple Developer Portal

1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Find and click: **com.example.botleji** (your main App ID)
3. Check ✅ **Live Activities**
4. Click **Continue** → **Save**
5. Repeat for: **com.example.botleji.LiveActivityWidgetExtension**

### Step 2: Regenerate Profiles

**Option A: In Xcode**
- Runner target → Signing & Capabilities → Provisioning Profile dropdown
- Click **"Download Manual Profiles"** or select **"Xcode Managed Profile"**

**Option B: In Developer Portal**
1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Find **"Bottleji App"** profile
3. Click **Edit**
4. Click **Generate** (regenerates with new entitlements)
5. **Download** the new profile
6. In Xcode: Double-click the downloaded .mobileprovision file

### Step 3: Clean & Rebuild

```bash
# In terminal
cd botleji/ios
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

Then rebuild in Xcode.

