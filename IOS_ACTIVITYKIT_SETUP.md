# iOS ActivityKit Setup Guide

## Overview

This guide explains how to set up ActivityKit for Dynamic Island and Live Activities in the iOS app.

## Files Created

1. **`LiveActivityManager.swift`** - Core manager for ActivityKit operations
2. **`LiveActivityPlugin.swift`** - Flutter platform channel plugin
3. **`LiveActivityWidget.swift`** - Widget UI for Dynamic Island and Lock Screen
4. **`Runner.entitlements`** - Required entitlements file

## Setup Steps

### 1. Add Files to Xcode Project

1. Open `botleji/ios/Runner.xcworkspace` in Xcode
2. Right-click on the `Runner` folder in the project navigator
3. Select "Add Files to Runner..."
4. Add the following files:
   - `LiveActivityManager.swift`
   - `LiveActivityPlugin.swift`
   - `LiveActivityWidget.swift` (create in `Runner/WidgetExtension/` folder)

### 2. Configure Entitlements

1. In Xcode, select the `Runner` target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability"
4. Add "Live Activities" capability
5. This will automatically add the entitlement to `Runner.entitlements`

**OR** manually add to `Runner.entitlements`:
```xml
<key>com.apple.developer.usernotifications.live-activities</key>
<true/>
```

### 3. Update Info.plist

Add the following to `Info.plist`:
```xml
<key>NSSupportsLiveActivities</key>
<true/>
```

### 4. Create Widget Extension (Optional but Recommended)

For better Dynamic Island support, create a Widget Extension:

1. In Xcode: File → New → Target
2. Select "Widget Extension"
3. Name it "LiveActivityWidgetExtension"
4. Check "Include Configuration Intent" (optional)
5. Copy `LiveActivityWidget.swift` to the extension folder
6. Update the extension's `Info.plist` to include:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```

### 5. Update Podfile (if needed)

If you encounter build issues, ensure your `Podfile` includes:
```ruby
platform :ios, '16.1'
```

### 6. Build and Run

1. Clean build folder: Product → Clean Build Folder (Shift+Cmd+K)
2. Build: Product → Build (Cmd+B)
3. Run on device (iPhone 14 Pro or later with iOS 16.1+)

## Testing

### Test on Device

1. Connect iPhone 14 Pro or later (Dynamic Island required)
2. Ensure iOS 16.1+ is installed
3. Run the app
4. Start a collection navigation
5. Check Dynamic Island for live activity

### Test on Simulator

- Dynamic Island is not available on simulator
- Live Activities on Lock Screen can be tested on simulator

## Troubleshooting

### Error: "ActivityKit is not available"

**Solution:**
- Ensure device is iPhone 14 Pro or later
- Ensure iOS 16.1+ is installed
- Check that Live Activities capability is added
- Verify entitlements file is correct

### Error: "Activities are not enabled"

**Solution:**
- Go to Settings → Face ID & Passcode (or Touch ID & Passcode)
- Enable "Live Activities" if available
- Restart the app

### Build Error: "Cannot find type 'Activity'"

**Solution:**
- Ensure `import ActivityKit` is present
- Check iOS deployment target is 16.1+
- Clean and rebuild

### Dynamic Island Not Showing

**Solution:**
- Ensure device has Dynamic Island (iPhone 14 Pro+)
- Check that activity is started correctly
- Verify widget extension is properly configured

## Code Structure

### LiveActivityManager

- Manages ActivityKit lifecycle
- Handles start, update, and end operations
- Checks availability

### LiveActivityPlugin

- Flutter platform channel bridge
- Converts Flutter calls to native Swift
- Handles method calls from Dart

### LiveActivityWidget

- Defines UI for Dynamic Island
- Supports compact, expanded, and minimal views
- Lock screen banner UI

## Dynamic Island Views

### Compact View
- Left: Collection icon
- Right: Timer (elapsed time)

### Expanded View
- Leading: Drop address
- Trailing: Timer
- Bottom: Distance and ETA

### Minimal View
- Single icon (when multiple activities)

## Next Steps

1. Test on physical device (iPhone 14 Pro+)
2. Customize UI in `LiveActivityWidget.swift`
3. Add more data fields if needed
4. Test background updates

## Notes

- Dynamic Island is only available on iPhone 14 Pro, iPhone 14 Pro Max, iPhone 15 series, iPhone 16 series
- Live Activities work on all iOS 16.1+ devices (but Dynamic Island requires specific hardware)
- Activities automatically end when app is terminated (unless configured otherwise)

