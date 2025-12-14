# Rebuild vs Restart - What's the Difference?

## 🔄 **Restart** (Hot Restart in Flutter)
- **What it does**: Reloads Dart code only
- **When to use**: After changing Dart/Flutter code
- **How to do it**: 
  - Press `R` in Flutter terminal
  - Or click "Hot Restart" in VS Code/Android Studio
  - Or stop and run `flutter run` again
- **Time**: ~5-10 seconds

## 🔨 **Rebuild** (Full Build in Xcode)
- **What it does**: Compiles Swift/Objective-C code + Dart code
- **When to use**: After changing **Swift/Objective-C** code (like Live Activity widget)
- **How to do it**:
  1. Open Xcode
  2. Product → Clean Build Folder (Shift+Cmd+K)
  3. Product → Build (Cmd+B) or Run (Cmd+R)
- **Time**: ~30-60 seconds (longer)

## 📝 **What We Changed**

Since we modified **Swift files** (`LiveActivityWidgetExtension.swift`), you need a **FULL REBUILD**:

### Files Changed:
- ✅ `botleji/ios/LiveActivityWidgetExtension/LiveActivityWidgetExtension.swift` (Swift)
- ✅ `botleji/lib/core/services/live_activities_package_service.dart` (Dart - restart OK)
- ✅ `botleji/lib/features/home/presentation/screens/home_screen.dart` (Dart - restart OK)
- ✅ `backend/src/modules/...` (Backend - needs redeployment)

## 🎯 **Steps to Rebuild**

### Option 1: Using Xcode (Recommended)
1. Open `botleji/ios/Runner.xcworkspace` in Xcode
2. **Product → Clean Build Folder** (Shift+Cmd+K)
3. **Product → Build** (Cmd+B) or **Run** (Cmd+R)
4. Wait for build to complete
5. App will install on device

### Option 2: Using Flutter CLI
```bash
cd botleji
flutter clean
flutter pub get
flutter build ios
# Then run from Xcode or:
flutter run
```

## ⚠️ **Important Notes**

- **Restart is NOT enough** for Swift changes - the widget extension won't update
- **Clean Build Folder** is important - clears cached Swift code
- **First build after Swift changes** takes longer (compiling Swift)
- **Subsequent builds** are faster (incremental)

## 🔍 **How to Verify Rebuild Worked**

After rebuilding, check:
1. Xcode console shows: "Building LiveActivityWidgetExtension..."
2. App installs on device
3. Live Activity shows the new collector pin (if collector is on the way)

## 📱 **For Backend Changes**

Backend changes need **redeployment**, not rebuild:
- Push code to repository
- Deploy to server
- Backend automatically restarts


