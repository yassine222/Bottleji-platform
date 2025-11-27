#!/bin/bash

echo "🚀 Moving Xcode to Applications and configuring it..."
echo ""

# Check if Xcode exists in Downloads
if [ ! -d "/Users/yassineromdhane/Downloads/Xcode.app" ]; then
    echo "❌ Xcode.app not found in Downloads folder!"
    echo "Please check where Xcode is located."
    exit 1
fi

# Check if Applications/Xcode.app already exists
if [ -d "/Applications/Xcode.app" ]; then
    echo "⚠️  Xcode.app already exists in /Applications"
    read -p "Do you want to replace it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    echo "Removing existing Xcode.app..."
    sudo rm -rf /Applications/Xcode.app
fi

# Move Xcode to Applications
echo "📦 Moving Xcode.app to /Applications (this may take a moment)..."
sudo mv /Users/yassineromdhane/Downloads/Xcode.app /Applications/Xcode.app

if [ $? -ne 0 ]; then
    echo "❌ Failed to move Xcode. Please check permissions."
    exit 1
fi

echo "✅ Xcode moved successfully!"
echo ""

# Switch xcode-select
echo "🔧 Configuring xcode-select..."
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

if [ $? -ne 0 ]; then
    echo "❌ Failed to switch xcode-select"
    exit 1
fi

echo "✅ xcode-select configured!"
echo ""

# Run first launch
echo "🚀 Running Xcode first launch setup (this may take a few minutes)..."
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
echo "✅ Xcode setup complete!"
echo ""
echo "Verifying installation..."
xcodebuild -version
echo ""
xcode-select -p
echo ""
echo "🎉 Done! Now try building your Flutter app:"
echo "   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji"
echo "   flutter clean"
echo "   flutter run"
