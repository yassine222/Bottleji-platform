# Widget Extension Setup - REQUIRED for Live Activities

## ⚠️ CRITICAL: Widget Extension is Required

**The activity is being created, but it won't display without a Widget Extension!**

ActivityKit creates the activity, but iOS needs a Widget Extension to render the UI for:
- Dynamic Island
- Lock Screen Live Activity
- Notification banner

## Quick Setup Steps

### Step 1: Create Widget Extension Target

1. **Open Xcode:**
   ```bash
   cd botleji/ios
   open Runner.xcworkspace
   ```

2. **Create New Target:**
   - File → New → Target
   - Select **"Widget Extension"**
   - Click **"Next"**

3. **Configure Extension:**
   - **Product Name:** `LiveActivityWidgetExtension`
   - **Organization Identifier:** (same as your app)
   - **Language:** Swift
   - ✅ Check **"Include Configuration Intent"** (optional, but recommended)
   - Click **"Finish"**

4. **Activate Scheme:**
   - Xcode will ask to activate the scheme
   - Click **"Activate"**

### Step 2: Add Widget Code

1. **In the new Widget Extension target:**
   - Find the main widget file (usually `LiveActivityWidgetExtension.swift` or similar)
   - **Replace its contents** with the code from `botleji/ios/Runner/WidgetExtension/LiveActivityWidget.swift`

2. **OR copy the file:**
   - Copy `LiveActivityWidget.swift` from `Runner/WidgetExtension/` folder
   - Add it to the Widget Extension target in Xcode
   - Make sure it's added to the Widget Extension target (not Runner target)

### Step 3: Update Widget Extension Info.plist

1. **Select Widget Extension target**
2. **Go to Info tab**
3. **Add to Info.plist:**
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   ```

### Step 4: Build Both Targets

1. **Select Runner scheme** (main app)
2. **Build:** Product → Build (Cmd+B)
3. **Select Widget Extension scheme**
4. **Build:** Product → Build (Cmd+B)
5. **Select Runner scheme again**
6. **Run on device**

### Step 5: Verify

1. **Run the app on device**
2. **Start a collection navigation**
3. **Check:**
   - Dynamic Island (if iPhone 14 Pro+)
   - Lock Screen (swipe up to see Live Activities)
   - Notification Center

## File Structure After Setup

```
Runner/
  ├── AppDelegate.swift
  ├── LiveActivityManager.swift
  ├── LiveActivityPlugin.swift
  └── ...

LiveActivityWidgetExtension/  ← New target
  ├── LiveActivityWidgetExtension.swift  ← Widget code here
  ├── Info.plist
  └── ...
```

## Important Notes

### Widget Extension Must:
- ✅ Be a separate target
- ✅ Have `NSSupportsLiveActivities = true` in Info.plist
- ✅ Contain the Widget code with `ActivityConfiguration`
- ✅ Be built and included in the app

### Common Mistakes:
- ❌ Widget code in Runner target (won't work)
- ❌ Widget Extension not built
- ❌ Missing `NSSupportsLiveActivities` in extension Info.plist
- ❌ Widget Extension not included in app scheme

## Testing

After setup:

1. **Build and run on device**
2. **Start navigation**
3. **Check console logs:**
   - Should see "✅ Live Activity started"
   - Should see "Activity ID: [id]"
4. **Check device:**
   - Dynamic Island (iPhone 14 Pro+)
   - Lock Screen Live Activity
   - Notification Center

## If Still Not Showing

1. **Check Widget Extension is built:**
   - Product → Scheme → Edit Scheme
   - Ensure Widget Extension is included

2. **Verify Widget code:**
   - Widget file must have `ActivityConfiguration`
   - Must use `CollectionActivityAttributes`

3. **Check device:**
   - iPhone 14 Pro+ for Dynamic Island
   - iOS 16.1+ for Live Activities
   - Live Activities enabled in Settings

4. **Restart device:**
   - Sometimes iOS needs a restart after adding Widget Extension

## Alternative: Test Without Widget Extension

If you want to test if ActivityKit is working (without UI):

1. Check console logs for "Activity started"
2. Check if activity appears in iOS Control Center
3. Verify no errors in Xcode console

But **UI won't display without Widget Extension!**

