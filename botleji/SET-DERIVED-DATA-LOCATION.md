# Fix Xcode Build Issues by Changing DerivedData Location

## The Workaround
Change the DerivedData folder location in Xcode Workspace Settings to avoid cache corruption issues.

## Steps to Fix

### Option 1: Through Xcode GUI (Recommended)

1. **Open the workspace in Xcode:**
   ```bash
   open /Users/yassineromdhane/FlutterProjects/PFE/botleji/ios/Runner.xcworkspace
   ```

2. **Go to Workspace Settings:**
   - Click `File` → `Workspace Settings...` (or `Project Settings...` if it's a project)
   - In the dialog, look for "Derived Data" section
   - Change from "Default" to "Custom location"
   - Set a custom path, for example:
     ```
     ~/Library/Developer/Xcode/DerivedData-Custom
     ```
     or
     ```
     /Users/yassineromdhane/Library/Developer/Xcode/DerivedData-Custom
     ```

3. **Click "Done"**

4. **Clean and rebuild:**
   - Press `Cmd + Shift + K` (Clean Build Folder)
   - Press `Cmd + B` (Build)

### Option 2: Set via Command Line (Alternative)

You can also set a custom DerivedData location via xcodebuild:

```bash
# Set custom DerivedData location
defaults write com.apple.dt.Xcode IDECustomDerivedDataLocation -string "$HOME/Library/Developer/Xcode/DerivedData-Custom"

# Or for just this workspace, you can use xcodebuild with -derivedDataPath
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji/ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -derivedDataPath ~/Library/Developer/Xcode/DerivedData-Custom clean build
```

## After Setting Custom Location

1. **Clean everything:**
   ```bash
   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
   flutter clean
   rm -rf ~/Library/Developer/Xcode/DerivedData-Custom
   ```

2. **Build from Xcode GUI first** (to initialize the new cache location):
   - Open workspace in Xcode
   - Build (Cmd+B)

3. **Then use Flutter:**
   ```bash
   flutter run
   ```

## Benefits
- Fresh cache location without corruption
- Avoids Xcode 16 module cache bugs
- Can easily clear by deleting the custom DerivedData folder
- Doesn't affect other Xcode projects (if using workspace-specific setting)

## Reverting
If you want to go back to default:
- In Xcode: File → Workspace Settings → Change back to "Default"
- Or: `defaults delete com.apple.dt.Xcode IDECustomDerivedDataLocation`
