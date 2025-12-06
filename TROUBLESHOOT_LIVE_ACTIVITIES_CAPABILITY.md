# Troubleshooting: Can't See Live Activities Capability in Xcode 16

## Issue
You have Xcode 16 but can't see "Live Activities" in the Capabilities list.

## Solutions

### Solution 1: Add Capability Manually via Entitlements File

Since you already have `Runner.entitlements` file, you can add it manually:

1. **In Xcode:**
   - Select **Runner** target
   - Go to **Signing & Capabilities** tab
   - Look for **"Code Signing Entitlements"** field
   - It should show: `Runner/Runner.entitlements`
   - If it's empty, click and select `Runner.entitlements`

2. **Check the entitlements file:**
   - In Project Navigator, find `Runner.entitlements`
   - Open it
   - It should contain:
     ```xml
     <key>com.apple.developer.usernotifications.live-activities</key>
     <true/>
     ```

3. **If the key is missing:**
   - Add it manually to `Runner.entitlements`
   - Save the file
   - Xcode should recognize it

### Solution 2: Add via Xcode UI (Alternative Method)

1. **Select Runner target**
2. **Go to Signing & Capabilities tab**
3. **Click "+ Capability"** (top left)
4. **Look for these options:**
   - "Live Activities" (if available)
   - Or search for "Live" or "Activity"
5. **If still not visible:**
   - Try typing "Live Activities" in the search box
   - Some Xcode versions show it differently

### Solution 3: Verify Project Settings

1. **Check iOS Deployment Target:**
   - Select **Runner** target
   - Go to **General** tab
   - Check **"Minimum Deployments"**
   - Should be **iOS 16.1** or higher
   - If lower, change it to **16.1**

2. **Check Build Settings:**
   - Select **Runner** target
   - Go to **Build Settings** tab
   - Search for "iOS Deployment Target"
   - Should be **16.1** or higher

### Solution 4: Manual Entitlements Edit

If Xcode UI doesn't show it, edit `Runner.entitlements` directly:

1. **Open `Runner.entitlements` in Xcode**
2. **Add this if missing:**
   ```xml
   <key>com.apple.developer.usernotifications.live-activities</key>
   <true/>
   ```
3. **Save the file**
4. **Clean and rebuild:**
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Build (Cmd+B)

### Solution 5: Check Info.plist

Verify `Info.plist` has:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### Solution 6: Verify Xcode Version

Even though you have Xcode 16, verify it's properly installed:

```bash
xcodebuild -version
```

Should show:
```
Xcode 16.x
Build version ...
```

### Solution 7: Restart Xcode

Sometimes Xcode needs a restart to recognize new capabilities:

1. **Quit Xcode completely**
2. **Reopen the project:**
   ```bash
   cd botleji/ios
   open Runner.xcworkspace
   ```
3. **Try adding capability again**

## Quick Verification Checklist

- [ ] `Runner.entitlements` file exists
- [ ] `Runner.entitlements` contains `com.apple.developer.usernotifications.live-activities`
- [ ] `Info.plist` contains `NSSupportsLiveActivities = true`
- [ ] iOS Deployment Target is 16.1+
- [ ] Code Signing Entitlements points to `Runner.entitlements`
- [ ] Xcode is restarted

## If Still Not Working

The capability might be added but not visible in the UI. Check:

1. **Open `Runner.entitlements` directly**
2. **Verify it has the Live Activities key**
3. **If it does, you're good!** The capability is added, even if not visible in the UI

The important thing is that the entitlements file has the correct key. Xcode UI is sometimes inconsistent.

## Test It

After adding the capability:

1. **Build the project** (Cmd+B)
2. **Check for errors**
3. **If no errors, the capability is working!**

The capability might work even if it doesn't show in the UI, as long as the entitlements file is correct.

