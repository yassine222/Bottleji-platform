# AppLogo Asset Configuration - REQUIRED

## Problem
The app logo shows as a blank rectangle because the asset isn't properly configured in Xcode.

## Solution: Configure Asset in Xcode

### Step 1: Open Xcode Project
```bash
cd botleji/ios
open Runner.xcworkspace
```

### Step 2: Add Asset to Widget Extension Target

1. **In Xcode Project Navigator:**
   - Find `LiveActivityWidgetExtension` folder
   - Expand `Assets.xcassets`
   - Find `AppLogo.imageset`

2. **Select `AppLogo.imageset` in the file navigator**

3. **In the File Inspector (right panel):**
   - Under "Target Membership"
   - ✅ **CHECK** `LiveActivityWidgetExtension`
   - ✅ **UNCHECK** `Runner` (if checked)

4. **Verify the asset:**
   - Click on `AppLogo.imageset`
   - You should see `AppLogo.png` in the asset viewer
   - Make sure it's set to "Universal" (not iPhone/iPad specific)

### Step 3: Clean and Rebuild

1. **Clean Build Folder:**
   - Product → Clean Build Folder (Shift+Cmd+K)

2. **Build Widget Extension:**
   - Select `LiveActivityWidgetExtension` scheme
   - Product → Build (Cmd+B)

3. **Build Runner:**
   - Select `Runner` scheme
   - Product → Build (Cmd+B)

4. **Run on Device:**
   - Make sure you're running on a physical device (Live Activities don't work in simulator)
   - Product → Run (Cmd+R)

### Step 4: Verify

After building, the logo should appear in:
- Lock Screen Live Activity
- Dynamic Island (all views)
- Notification banner

## Alternative: If Still Not Working

If the logo still doesn't appear, try using the app icon instead:

1. Copy the app icon from `Runner/Assets.xcassets/AppIcon.appiconset/`
2. Add it to `LiveActivityWidgetExtension/Assets.xcassets/`
3. Name it `AppLogo`
4. Make sure it's added to the Widget Extension target

## Troubleshooting

- **Blank rectangle:** Asset not added to Widget Extension target
- **Image not found error:** Asset name mismatch or wrong bundle
- **Wrong size:** Image needs to be properly scaled (we're using resizable/scaledToFit)

