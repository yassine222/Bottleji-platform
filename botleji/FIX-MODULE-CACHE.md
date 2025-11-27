# Fix Xcode Module Cache Issues

## The Problem
Xcode is trying to create module cache files but the directory structure doesn't exist, causing build failures.

## Solution Steps

### Step 1: Run Xcode Setup Commands (REQUIRED)
Open Terminal and run these commands (you'll need your password):

```bash
# Run Xcode first launch setup
sudo xcodebuild -runFirstLaunch

# Accept Xcode license
sudo xcodebuild -license accept
```

### Step 2: Build from Xcode GUI First
This lets Xcode create the module cache properly:

1. **Open the project in Xcode:**
   ```bash
   open /Users/yassineromdhane/FlutterProjects/PFE/botleji/ios/Runner.xcworkspace
   ```

2. **In Xcode:**
   - Select your device "Yassine" from the device dropdown (top toolbar)
   - Press `Cmd + Shift + K` (Clean Build Folder)
   - Press `Cmd + B` (Build)
   - Wait for the build to complete (this creates the module cache)

3. **If build succeeds in Xcode**, then try Flutter:
   ```bash
   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
   flutter run
   ```

### Step 3: Alternative - Use the Fixed Build Script
If Step 2 doesn't work, use the script I created:

```bash
/Users/yassineromdhane/FlutterProjects/PFE/botleji/build-ios-fixed.sh
```

### Step 4: If Still Failing - Manual Directory Creation
Create the module cache directory manually before each build:

```bash
mkdir -p ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
chmod -R 755 ~/Library/Developer/Xcode/DerivedData
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
flutter run
```

## Why This Happens
Xcode 16 with iOS 18 SDK has issues creating module cache directories automatically when building from command line. Building from Xcode GUI first initializes the cache properly.

## Quick Fix Command
Run this before each build:

```bash
mkdir -p ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex && chmod -R 755 ~/Library/Developer/Xcode/DerivedData && cd /Users/yassineromdhane/FlutterProjects/PFE/botleji && flutter run
```
