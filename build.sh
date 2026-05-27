#!/bin/bash
# Pill Build Script
# Usage: bash build.sh

set -e

echo "💊 Building Pill..."

# Check Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found. Install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

echo "✅ Swift $(swift --version 2>&1 | head -1)"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo "✅ macOS $MACOS_VERSION"

# Build
echo "🔨 Building..."
swift build 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📦 Deploy with:"
    echo "   mkdir -p ~/Applications/Pill.app/Contents/MacOS"
    echo "   cp .build/debug/Pill ~/Applications/Pill.app/Contents/MacOS/Pill"
    echo "   cp Sources/DynamicNotch/Info.plist ~/Applications/Pill.app/Contents/Info.plist"
    echo "   open ~/Applications/Pill.app"
else
    echo ""
    echo "❌ Build failed. Common fixes:"
    echo "   1. sudo xcode-select --reset"
    echo "   2. xcode-select --install"
    echo "   3. Make sure you're in the Pill/ directory"
    exit 1
fi
