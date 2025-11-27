#!/bin/bash

# Fix SDK Stat Cache Issue
echo "🔧 Fixing SDK stat cache issue..."

# Clear all Xcode caches
echo "Clearing all Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Create fresh directories
echo "Creating fresh cache directories..."
mkdir -p ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
mkdir -p ~/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex

# Set proper permissions
echo "Setting permissions..."
chmod -R 755 ~/Library/Developer/Xcode/DerivedData

# Clean Flutter
echo "Cleaning Flutter build..."
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji
flutter clean > /dev/null 2>&1

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get > /dev/null 2>&1

# Reinstall pods
echo "Reinstalling CocoaPods..."
cd ios
export LANG=en_US.UTF-8
pod install > /dev/null 2>&1

echo ""
echo "✅ Setup complete!"
echo ""
echo "Now try building from Xcode:"
echo "1. Open: open ios/Runner.xcworkspace"
echo "2. Select your device"
echo "3. Press Cmd+Shift+K (Clean)"
echo "4. Press Cmd+B (Build)"
echo ""
echo "Or try Flutter:"
echo "   flutter run"
