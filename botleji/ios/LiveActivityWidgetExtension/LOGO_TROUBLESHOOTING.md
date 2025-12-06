# App Logo Troubleshooting Guide

## Issue: Logo shows as blank rectangle

The logo might not be loading due to bundle configuration. Here's a comprehensive troubleshooting guide.

## Step 1: Verify Asset in Xcode

1. **Open Xcode:**
   ```bash
   cd botleji/ios
   open Runner.xcworkspace
   ```

2. **Check Asset Target Membership:**
   - Select `LiveActivityWidgetExtension` → `Assets.xcassets` → `AppLogo.imageset`
   - In File Inspector (right panel), check "Target Membership"
   - ✅ **MUST CHECK** `LiveActivityWidgetExtension`
   - ❌ **UNCHECK** `Runner` (if checked)

3. **Verify Image File:**
   - Click on `AppLogo.imageset` in Xcode
   - You should see `AppLogo.png` in the asset viewer
   - If not, drag the image file into the asset set

## Step 2: Check Bundle Configuration

The code now tries multiple approaches:
1. `UIImage(named: "AppLogo", in: Bundle.main, compatibleWith: nil)` - Main bundle
2. `UIImage(named: "AppLogo")` - Default bundle
3. Fallback to system icon if both fail

## Step 3: Alternative - Use App Icon

If the logo still doesn't work, try using the app icon:

1. **Copy App Icon:**
   - In Xcode, go to `Runner` → `Assets.xcassets` → `AppIcon.appiconset`
   - Copy one of the icon files (e.g., `Icon-App-60x60@2x.png`)

2. **Add to Widget Extension:**
   - Go to `LiveActivityWidgetExtension` → `Assets.xcassets`
   - Right-click → "New Image Set"
   - Name it `AppLogo`
   - Drag the copied icon into the 1x slot
   - Make sure it's added to `LiveActivityWidgetExtension` target

3. **Rebuild:**
   - Clean Build Folder (Shift+Cmd+K)
   - Build Widget Extension (Cmd+B)
   - Build Runner (Cmd+B)

## Step 4: Debug Logging

To see what's happening, you can add debug logging in the Swift code:

```swift
// In AppLogoView function, add:
print("🔍 Trying to load AppLogo...")
if let image = UIImage(named: "AppLogo", in: Bundle.main, compatibleWith: nil) {
    print("✅ Found in Bundle.main")
} else if let image = UIImage(named: "AppLogo") {
    print("✅ Found in default bundle")
} else {
    print("❌ Not found, using fallback")
}
```

## Step 5: Verify Bundle Path

The Widget Extension has its own bundle. Check if the asset is in the correct location:

- Widget Extension bundle: `LiveActivityWidgetExtension.appex/Assets.xcassets/AppLogo.imageset/`
- Main app bundle: `Runner.app/Assets.xcassets/AppLogo.imageset/`

The asset MUST be in the Widget Extension bundle, not the main app bundle.

## Common Issues:

1. **Asset not in Widget Extension target** → Most common issue
2. **Wrong bundle** → Asset in Runner instead of Widget Extension
3. **Image file missing** → File not actually in the imageset folder
4. **Build cache** → Clean build folder and rebuild

## Current Implementation:

The code uses a helper function `AppLogoView()` that:
- Tries `Bundle.main` first
- Falls back to default bundle
- Shows green map pin icon if logo not found (no blank rectangle)

If you see the green map pin, the logo asset is not being found. Follow the steps above to fix it.

