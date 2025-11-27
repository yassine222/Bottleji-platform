#!/bin/bash

# Initialize Xcode caches by building a simple project
echo "🔧 Initializing Xcode SDK stat cache..."

# Create a minimal Xcode project to trigger cache creation
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Create a simple Swift file
cat > main.swift << 'EOF'
import Foundation
print("Initializing Xcode cache")
EOF

# Try to compile it (this will trigger Xcode to create SDK caches)
xcrun swiftc main.swift -sdk $(xcrun --show-sdk-path --sdk iphoneos) 2>&1 | head -5 || true

# Clean up
cd /
rm -rf "$TEMP_DIR"

echo "✅ Cache initialization attempted"
echo ""
echo "Now try building your Flutter app from Xcode GUI:"
echo "1. Open: open /Users/yassineromdhane/FlutterProjects/PFE/botleji/ios/Runner.xcworkspace"
echo "2. Select your device"
echo "3. Product → Clean Build Folder (Cmd+Shift+K)"
echo "4. Product → Build (Cmd+B)"
