#!/bin/bash

# Pre-build fix for Xcode 16 module cache issues
# This creates the necessary directory structure before building

MODULE_CACHE_BASE="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
SDK_CACHE_BASE="$HOME/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex"

# Create base directories
mkdir -p "$MODULE_CACHE_BASE"
mkdir -p "$SDK_CACHE_BASE"

# Create some common hash directories that Xcode might use
# (Xcode generates these dynamically, but we'll create a few common ones)
for hash in "8LBHOKYZ6P10" "3I2VY0PBONYU9" "2OQ1MN8CP9NUK" "3TKS1921BVH7O"; do
    mkdir -p "$MODULE_CACHE_BASE/$hash"
    chmod 755 "$MODULE_CACHE_BASE/$hash"
done

# Set permissions
chmod -R 755 "$HOME/Library/Developer/Xcode/DerivedData"

echo "✅ Pre-build directories created"
