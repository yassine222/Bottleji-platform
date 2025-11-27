#!/bin/bash

# Fix for Xcode module cache issues
# This script ensures the module cache directory exists before building

set -e

echo "🔧 Setting up module cache directories..."

# Create module cache directory with proper permissions
MODULE_CACHE_DIR="$HOME/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
mkdir -p "$MODULE_CACHE_DIR"
chmod -R 755 "$MODULE_CACHE_DIR"

# Also create SDK cache directory
SDK_CACHE_DIR="$HOME/Library/Developer/Xcode/DerivedData/SDKStatCaches.noindex"
mkdir -p "$SDK_CACHE_DIR"
chmod -R 755 "$SDK_CACHE_DIR"

# Set environment variable to use this directory
export CLANG_MODULE_CACHE_DIR="$MODULE_CACHE_DIR"

echo "✅ Module cache directories ready"
echo ""

# Change to project directory
cd /Users/yassineromdhane/FlutterProjects/PFE/botleji

# Clean first
echo "🧹 Cleaning build..."
flutter clean > /dev/null 2>&1 || true

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get > /dev/null 2>&1

# Build
echo "🔨 Building iOS app..."
echo ""

# Use the environment variable when building
CLANG_MODULE_CACHE_DIR="$MODULE_CACHE_DIR" flutter build ios --no-codesign

echo ""
echo "✅ Build complete!"
