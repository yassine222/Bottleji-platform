#!/bin/bash

echo "🔍 Finding Xcode installation..."

# Check common locations
XCODE_PATHS=(
  "/Applications/Xcode.app"
  "/Applications/Xcode-beta.app"
  "$HOME/Applications/Xcode.app"
  "$HOME/Applications/Xcode-beta.app"
)

XCODE_FOUND=""

for path in "${XCODE_PATHS[@]}"; do
  if [ -d "$path" ]; then
    XCODE_FOUND="$path"
    echo "✅ Found Xcode at: $path"
    break
  fi
done

if [ -z "$XCODE_FOUND" ]; then
  echo "❌ Xcode not found in standard locations."
  echo ""
  echo "Please find Xcode manually:"
  echo "1. Open Finder"
  echo "2. Search for 'Xcode'"
  echo "3. Right-click on Xcode.app → Get Info"
  echo "4. Note the full path"
  echo ""
  echo "Then run:"
  echo "  sudo xcode-select --switch /path/to/Xcode.app/Contents/Developer"
  echo "  sudo xcodebuild -runFirstLaunch"
  exit 1
fi

echo ""
echo "🔧 Configuring Xcode..."

# Switch xcode-select
echo "Switching xcode-select to: $XCODE_FOUND/Contents/Developer"
sudo xcode-select --switch "$XCODE_FOUND/Contents/Developer"

# Run first launch
echo ""
echo "Running Xcode first launch setup..."
sudo xcodebuild -runFirstLaunch

echo ""
echo "✅ Xcode configuration complete!"
echo ""
echo "Next steps:"
echo "1. Accept Xcode license: sudo xcodebuild -license accept"
echo "2. Plug in your iOS device"
echo "3. Trust the computer on your device if prompted"
echo "4. Run: flutter devices"

