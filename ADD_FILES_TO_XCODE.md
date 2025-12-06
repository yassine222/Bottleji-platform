# How to Add Live Activity Files to Xcode

## Problem
The Swift files exist in the file system but are not visible in Xcode because they haven't been added to the Xcode project.

## Solution: Add Files to Xcode Project

### Method 1: Using Xcode GUI (Recommended)

1. **Open the project in Xcode:**
   ```bash
   cd botleji/ios
   open Runner.xcworkspace
   ```
   ⚠️ **Important:** Open `.xcworkspace`, NOT `.xcodeproj`

2. **In Xcode Project Navigator:**
   - Find the `Runner` folder (blue folder icon)
   - Right-click on `Runner` folder
   - Select **"Add Files to Runner..."**

3. **Navigate to the files:**
   - Navigate to: `botleji/ios/Runner/`
   - Select these files:
     - `LiveActivityManager.swift`
     - `LiveActivityPlugin.swift`
   - **Options:**
     - ✅ Check "Copy items if needed" (if not already in folder)
     - ✅ Check "Create groups" (not "Create folder references")
     - ✅ Select "Runner" target
   - Click **"Add"**

4. **For Widget Extension (Optional):**
   - If you want to add the widget file:
   - Navigate to: `botleji/ios/Runner/WidgetExtension/`
   - Select: `LiveActivityWidget.swift`
   - Add to target (if you create a Widget Extension target)

### Method 2: Verify Files Are Added

After adding, you should see in Xcode Project Navigator:
```
Runner/
  ├── AppDelegate.swift
  ├── LiveActivityManager.swift  ← Should appear here
  ├── LiveActivityPlugin.swift   ← Should appear here
  ├── Assets.xcassets/
  └── ...
```

### Method 3: Check Build Settings

1. Select `LiveActivityManager.swift` in Xcode
2. In File Inspector (right panel), check:
   - **Target Membership:** Should have "Runner" checked ✅
   - **Location:** Should be "Relative to Group"

3. Repeat for `LiveActivityPlugin.swift`

### Method 4: If Files Still Don't Appear

1. **Clean Build Folder:**
   - Product → Clean Build Folder (Shift+Cmd+K)

2. **Close and Reopen Xcode**

3. **Check File System:**
   ```bash
   ls -la botleji/ios/Runner/*.swift
   ```
   Should show:
   - AppDelegate.swift
   - LiveActivityManager.swift
   - LiveActivityPlugin.swift

4. **Manually Add via Terminal (if needed):**
   ```bash
   cd botleji/ios
   # Files should already exist, but verify:
   ls Runner/LiveActivity*.swift
   ```

### Method 5: Verify Entitlements

1. In Xcode, select **Runner** target
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"**
4. Add **"Live Activities"**
5. This should automatically update `Runner.entitlements`

### Troubleshooting

#### Error: "Cannot find type 'Activity'"
- Ensure `import ActivityKit` is in the file
- Check iOS deployment target is 16.1+

#### Error: "No such module 'ActivityKit'"
- Clean build folder
- Ensure iOS 16.1+ is set in deployment target
- Rebuild project

#### Files Not Compiling
1. Select the file in Xcode
2. Check Target Membership (should be "Runner")
3. Verify file is in correct location
4. Clean and rebuild

### Quick Verification Checklist

- [ ] Files exist in `botleji/ios/Runner/` folder
- [ ] Files are visible in Xcode Project Navigator
- [ ] Files have "Runner" target membership
- [ ] `Runner.entitlements` exists and has Live Activities capability
- [ ] `Info.plist` has `NSSupportsLiveActivities = true`
- [ ] `AppDelegate.swift` registers the plugin
- [ ] iOS deployment target is 16.1+

### After Adding Files

1. **Build the project:**
   - Product → Build (Cmd+B)
   - Should compile without errors

2. **Check for warnings:**
   - Look for any import errors
   - Fix any missing imports

3. **Test on device:**
   - Connect iPhone 14 Pro or later
   - Run the app
   - Start a collection navigation
   - Check Dynamic Island

## Alternative: Use Flutter's Plugin Registration

If you prefer, you can also register the plugin in `AppDelegate.swift` using Flutter's plugin registration system, but the current implementation should work once files are added to the project.

