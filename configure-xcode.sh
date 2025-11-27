#!/bin/bash

echo "🔧 Configuring Xcode for Flutter development..."
echo ""

# Check if Xcode exists in Applications
if [ ! -d "/Applications/Xcode.app" ]; then
    echo "❌ Xcode.app not found in /Applications!"
    echo "Please install Xcode first."
    exit 1
fi

echo "✅ Xcode found in /Applications"
echo ""

# Switch xcode-select
echo "🔧 Switching xcode-select to /Applications/Xcode.app..."
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

if [ $? -ne 0 ]; then
    echo "❌ Failed to switch xcode-select"
    exit 1
fi

echo "✅ xcode-select configured!"
echo ""

# Verify
echo "Current xcode-select path:"
xcode-select -p
echo ""

# Run first launch
echo "🚀 Running Xcode first launch setup (this may take a few minutes)..."
echo "This will install additional components..."
sudo xcodebuild -runFirstLaunch

if [ $? -ne 0 ]; then
    echo "⚠️  First launch setup had issues, but continuing..."
fi

echo ""

# Accept license
echo "📝 Accepting Xcode license..."
sudo xcodebuild -license accept

if [ $? -ne 0 ]; then
    echo "⚠️  License acceptance had issues, but continuing..."
fi

echo ""
echo "✅ Xcode configuration complete!"
echo ""
echo "Verifying installation..."
xcodebuild -version
echo ""
echo "🎉 Done! Now try building your Flutter app:"
echo "   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji"
echo "   flutter clean"
echo "   flutter run"
