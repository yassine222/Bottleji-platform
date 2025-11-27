#!/bin/bash

# Fix iOS Build Module Cache Issues
echo "🔧 Fixing iOS build module cache issues..."

cd /Users/yassineromdhane/FlutterProjects/PFE/botleji

# 1. Clean everything
echo "Cleaning Flutter build..."
flutter clean

# 2. Remove all caches
echo "Removing Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData/*/ModuleCache.noindex

# 3. Create fresh directories
echo "Creating fresh cache directories..."
mkdir -p ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
mkdir -p ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex

# 4. Set permissions
echo "Setting permissions..."
chmod -R 755 ~/Library/Developer/Xcode/DerivedData

# 5. Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# 6. Reinstall pods
echo "Reinstalling CocoaPods..."
cd ios
export LANG=en_US.UTF-8
pod install

# 7. Try building
echo ""
echo "✅ Setup complete! Now try building:"
echo "   flutter run"
echo ""
echo "If it still fails, try opening the project in Xcode:"
echo "   open ios/Runner.xcworkspace"
echo "   Then: Product → Clean Build Folder (Cmd+Shift+K)"
echo "   Then: Product → Build (Cmd+B)"
