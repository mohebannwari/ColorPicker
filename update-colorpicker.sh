#!/bin/bash

# Update ColorPicker (Tint) - Rebuild and reinstall the app
# Usage: ./update-colorpicker.sh

set -e  # Exit on error

echo "🔨 Building ColorPicker (Release)..."
xcodebuild -project ColorPicker.xcodeproj -scheme ColorPicker -configuration Release clean build > /dev/null 2>&1

echo "📦 Installing to /Applications..."
if [ -d "/Applications/Tint.app" ]; then
    # Quit the app if it's running
    osascript -e 'quit app "Tint"' 2>/dev/null || true
    sleep 0.5
    rm -rf "/Applications/Tint.app"
fi

cp -R ~/Library/Developer/Xcode/DerivedData/ColorPicker-*/Build/Products/Release/ColorPicker.app /Applications/

# Rename the app to match the display name "Tint"
mv "/Applications/ColorPicker.app" "/Applications/Tint.app"

echo "🚀 Launching Tint..."
open -a /Applications/Tint.app

echo "✅ Tint updated successfully!"
