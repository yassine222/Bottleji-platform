# Live Activity Not Showing - Troubleshooting Guide

## Issue
Live Activity is detected/initialized but nothing is displayed on the device.

## Common Causes

### 1. Widget Extension Not Set Up
**Problem:** ActivityKit requires a Widget Extension to display the UI.

**Solution:** Create a Widget Extension target in Xcode:
1. File → New → Target
2. Select "Widget Extension"
3. Name it "LiveActivityWidgetExtension"
4. Check "Include Configuration Intent" (optional)
5. Copy `LiveActivityWidget.swift` to the extension
6. Build both targets

### 2. Live Activities Disabled in Settings
**Problem:** User has disabled Live Activities in iOS Settings.

**Solution:**
- Go to Settings → Face ID & Passcode (or Touch ID & Passcode)
- Scroll to "Allow Access When Locked"
- Enable "Live Activities"
- Restart the app

### 3. Device Doesn't Support Dynamic Island
**Problem:** Device is not iPhone 14 Pro or later.

**Solution:**
- Dynamic Island requires iPhone 14 Pro, iPhone 14 Pro Max, iPhone 15 series, or iPhone 16 series
- Live Activities on Lock Screen work on all iOS 16.1+ devices
- Check device model in Settings → General → About

### 4. iOS Version Too Old
**Problem:** iOS version is below 16.1.

**Solution:**
- Update to iOS 16.1 or later
- Check version in Settings → General → About

### 5. Widget Extension Not Running
**Problem:** Widget Extension target is not built/running.

**Solution:**
- Build the Widget Extension target
- Ensure it's included in the app scheme
- Check Xcode build logs for errors

## Debug Steps

### Step 1: Check Console Logs

Look for these logs when starting navigation:
```
🔵 iOS: Checking ActivityKit availability...
🔵 iOS: ActivityKit available: true/false
✅ iOS ActivityKit initialized successfully
🔵 iOS: Attempting to start live activity...
✅ Dynamic Island activity started
✅ Activity ID: [some-id]
```

### Step 2: Verify Activity is Created

Check if activity is actually created:
- Look for "✅ Live Activity started" in logs
- Check for "Activity ID" in logs
- If you see errors, note the error message

### Step 3: Check Device Settings

1. **Settings → Face ID & Passcode**
   - Enable "Live Activities" if available

2. **Settings → Notifications**
   - Check app notification settings
   - Ensure notifications are enabled

### Step 4: Test on Lock Screen

Even if Dynamic Island doesn't show, Live Activities should appear on:
- **Lock Screen** (swipe up to see)
- **Dynamic Island** (if supported device)

## Quick Fixes

### Fix 1: Add Widget Extension (Required)

**This is likely the issue!** ActivityKit needs a Widget Extension to display UI.

1. In Xcode: File → New → Target
2. Select "Widget Extension"
3. Name: "LiveActivityWidgetExtension"
4. Language: Swift
5. Check "Include Configuration Intent" (optional)
6. Click "Finish"
7. Copy `LiveActivityWidget.swift` content to the extension's main file
8. Build the extension target
9. Run the app again

### Fix 2: Verify Entitlements

1. Select **Runner** target
2. Go to **Signing & Capabilities**
3. Ensure "Live Activities" capability is added
4. Check `Runner.entitlements` has the key

### Fix 3: Check Info.plist

Verify `Info.plist` has:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

## Testing Checklist

- [ ] Device is iPhone 14 Pro or later (for Dynamic Island)
- [ ] iOS version is 16.1 or later
- [ ] Live Activities enabled in Settings
- [ ] Widget Extension target exists and is built
- [ ] `LiveActivityWidget.swift` is in Widget Extension
- [ ] Entitlements file has Live Activities capability
- [ ] Info.plist has `NSSupportsLiveActivities = true`
- [ ] Console shows "Activity started" message
- [ ] No errors in Xcode console

## What to Check in Console

When you start navigation, you should see:
1. `🔵 iOS: Checking ActivityKit availability...`
2. `✅ iOS ActivityKit initialized successfully`
3. `🔵 iOS: Attempting to start live activity...`
4. `✅ Dynamic Island activity started`
5. `✅ Activity ID: [id]`

If you see errors instead, share the error message.

## Alternative: Test Without Widget Extension

If Widget Extension setup is complex, you can test if ActivityKit is working by:
1. Checking console logs for activity creation
2. Looking for activity in iOS Control Center (swipe down from top right)
3. Checking if activity appears on Lock Screen

## Next Steps

1. **Check console logs** - What messages do you see?
2. **Verify Widget Extension** - Is it set up?
3. **Check device** - Is it iPhone 14 Pro+ with iOS 16.1+?
4. **Test on Lock Screen** - Does it appear there?

Share the console logs and I can help diagnose further!

