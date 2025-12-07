# Fix: Images Not Showing in Live Activity

## Quick Fix Steps

### Step 1: Clean Build (IMPORTANT)

1. **In Xcode:**
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Wait for it to complete

2. **Delete Derived Data:**
   - Xcode → Settings → Locations
   - Click arrow next to Derived Data path
   - Delete the folder for your project
   - Or run: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`

### Step 2: Verify Asset Target Membership

1. **Open Xcode:**
   ```bash
   cd botleji/ios
   open Runner.xcworkspace
   ```

2. **Check Each Image File:**
   - Select `LiveActivityWidgetExtension` → `Assets.xcassets` → `AppLogo.imageset`
   - Click on each image file:
     - `AppLogo.png`
     - `live_activity_icon_compact.png`
     - `live_activity_icon_expanded.png`
     - `live_activity_icon_minimal.png`
   
3. **For EACH image file:**
   - Select the file in Project Navigator
   - In File Inspector (right panel)
   - Under "Target Membership"
   - ✅ **CHECK** `LiveActivityWidgetExtension`
   - ❌ **UNCHECK** `Runner` (if checked)

### Step 3: Rebuild Widget Extension

1. **Select Widget Extension Scheme:**
   - In Xcode, select `LiveActivityWidgetExtension` scheme (top toolbar)
   
2. **Build Widget Extension:**
   - Product → Build (Cmd+B)
   - Wait for build to complete
   - Check for any errors

3. **Select Runner Scheme:**
   - Switch back to `Runner` scheme

4. **Build Runner:**
   - Product → Build (Cmd+B)

### Step 4: Uninstall and Reinstall App

**This is important!** Widget Extensions are embedded in the app, so you need to:

1. **Delete App from Device:**
   - Long press app icon
   - Tap "Remove App"
   - Confirm deletion

2. **Or via Xcode:**
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Run (Cmd+R)
   - This will reinstall the app with new Widget Extension

### Step 5: Verify Images Are Loaded

After reinstalling, check console logs. You should see:
- No errors about missing images
- Live Activity should show your custom icons

## Alternative: Check Image Names

Make sure the image file names match exactly what the code expects:

- ✅ `live_activity_icon_compact.png`
- ✅ `live_activity_icon_expanded.png`
- ✅ `live_activity_icon_minimal.png`
- ✅ `AppLogo.png`

## Debug: Add Logging

If still not working, we can add debug logging to see what's happening. The code tries:
1. `UIImage(named: "live_activity_icon_compact", in: Bundle.main)`
2. `UIImage(named: "live_activity_icon_compact")`
3. Falls back to `AppLogo.png`
4. Falls back to system icon

## Common Issues

1. **Images not in Widget Extension target** → Most common
2. **Derived data cache** → Clean build folder
3. **App not reinstalled** → Widget Extension is embedded, needs reinstall
4. **Wrong bundle** → Images in Runner instead of Widget Extension

## Quick Checklist

- [ ] Cleaned build folder
- [ ] Deleted derived data
- [ ] All images added to `LiveActivityWidgetExtension` target
- [ ] Built Widget Extension separately
- [ ] Built Runner
- [ ] Uninstalled app from device
- [ ] Reinstalled app
- [ ] Tested Live Activity

## If Still Not Working

1. Check Xcode console for errors
2. Verify image files exist in the imageset folder
3. Try using just `AppLogo.png` first to test
4. Check that images are not corrupted
5. Verify image sizes are reasonable (not too large)


