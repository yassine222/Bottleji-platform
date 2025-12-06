# Xcode Version Requirements for Live Activities

## Minimum Xcode Version

**Xcode 14.1 or later** is required to develop Live Activities.

### Why?
- Live Activities were introduced in **iOS 16.1** (October 2022)
- **Xcode 14.1** was the first version to support iOS 16.1 development
- ActivityKit framework requires Xcode 14.1+

## Recommended Versions

### For Best Compatibility:
- **Xcode 14.1+** (minimum)
- **Xcode 15.0+** (recommended for iOS 17+)
- **Xcode 16.0+** (latest, for iOS 18+)

## Check Your Xcode Version

1. Open Xcode
2. Go to: **Xcode → About Xcode**
3. Check the version number

Or in Terminal:
```bash
xcodebuild -version
```

## iOS Deployment Target

Your project should have:
- **iOS Deployment Target:** 16.1 or higher
- This is set in:
  - Xcode: Project Settings → Deployment Info → iOS Deployment Target
  - Or in `Podfile`: `platform :ios, '16.1'`

## Device Requirements

### For Dynamic Island (Live Activities on Dynamic Island):
- **iPhone 14 Pro** or later
- **iPhone 14 Pro Max** or later
- **iPhone 15** series
- **iPhone 16** series
- **iOS 16.1+**

### For Live Activities (Lock Screen):
- Any iPhone with **iOS 16.1+**
- Works on older iPhones (but no Dynamic Island)

## If You Don't Have Xcode 14.1+

### Option 1: Update Xcode
1. Open App Store
2. Search for "Xcode"
3. Update to latest version (or download if not installed)

### Option 2: Download Specific Version
- Visit [Apple Developer Downloads](https://developer.apple.com/download/)
- Download Xcode 14.1 or later
- Requires Apple Developer account (free)

## Verify Capability Availability

1. Open Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Click **"+ Capability"**
5. Look for **"Live Activities"**
   - ✅ If you see it → Xcode version is correct
   - ❌ If you don't see it → Update Xcode

## Common Issues

### Issue: "Live Activities" not in Capabilities list
**Solution:** Update Xcode to 14.1 or later

### Issue: Build errors about ActivityKit
**Solution:** 
- Ensure iOS deployment target is 16.1+
- Update Xcode to latest version

### Issue: Capability added but not working
**Solution:**
- Check `Runner.entitlements` has the capability
- Verify `Info.plist` has `NSSupportsLiveActivities = true`
- Test on physical device (iPhone 14 Pro+)

## Summary

| Requirement | Version |
|------------|---------|
| **Minimum Xcode** | 14.1 |
| **Recommended Xcode** | 15.0+ |
| **iOS Deployment Target** | 16.1+ |
| **Device (Dynamic Island)** | iPhone 14 Pro+ |
| **iOS Version** | 16.1+ |

## Quick Check

Run this to check your Xcode version:
```bash
xcodebuild -version
```

Should show:
```
Xcode 14.1
Build version ...
```

Or higher (14.2, 15.0, 16.0, etc.)

