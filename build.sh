#!/bin/bash
# Pill Build Script
# Usage: bash build.sh

set -e

echo "💊 Building Pill..."

# Check Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift not found."
    echo ""
    echo "Fix: Install Xcode Command Line Tools"
    echo "   xcode-select --install"
    echo ""
    echo "Or install full Xcode from App Store (free)."
    exit 1
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "✅ $SWIFT_VERSION"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
echo "✅ macOS $MACOS_VERSION"

# Check if PackageDescription framework exists
if ! swift package describe 2>/dev/null; then
    echo ""
    echo "⚠️  Swift Package Manager may be broken."
    echo ""
    echo "Fix: Reinstall Command Line Tools"
    echo "   sudo rm -rf /Library/Developer/CommandLineTools"
    echo "   xcode-select --install"
    echo ""
    echo "Or install full Xcode from App Store."
    echo ""
fi

# Build
echo ""
echo "🔨 Building with swift build..."
echo ""

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
    echo "❌ Build failed."
    echo ""
    echo "Common fixes:"
    echo "   1. sudo rm -rf /Library/Developer/CommandLineTools && xcode-select --install"
    echo "   2. Install full Xcode from App Store"
    echo "   3. Make sure you're in the Pill/ directory"
    exit 1
fi
