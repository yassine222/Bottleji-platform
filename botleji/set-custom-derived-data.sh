#!/bin/bash

# Set custom DerivedData location for Xcode
# This helps avoid cache corruption issues in Xcode 16

CUSTOM_DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData-Custom"

echo "🔧 Setting up custom DerivedData location..."

# Create custom directory
mkdir -p "$CUSTOM_DERIVED_DATA"
echo "✅ Created: $CUSTOM_DERIVED_DATA"

# Set via defaults (affects all Xcode projects)
echo ""
echo "Setting Xcode preference for custom DerivedData location..."
defaults write com.apple.dt.Xcode IDECustomDerivedDataLocation -string "$CUSTOM_DERIVED_DATA"

if [ $? -eq 0 ]; then
    echo "✅ Xcode preference set successfully"
else
    echo "⚠️  Could not set preference (may need to do it manually in Xcode)"
fi

echo ""
echo "📝 Next steps:"
echo "1. Open Xcode: open ios/Runner.xcworkspace"
echo "2. Go to: File → Workspace Settings..."
echo "3. Set Derived Data to: $CUSTOM_DERIVED_DATA"
echo "4. Clean and build (Cmd+Shift+K, then Cmd+B)"
echo ""
echo "Or use Flutter with custom path:"
echo "   cd /Users/yassineromdhane/FlutterProjects/PFE/botleji"
echo "   flutter clean"
echo "   flutter run"
