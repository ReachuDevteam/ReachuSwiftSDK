#!/bin/bash

# Script to add ReachuSwiftSDK as a local package dependency to tv2demo
# This adds the SDK from the parent directory

echo "🔧 Adding ReachuSwiftSDK as local dependency to tv2demo..."

# Path to SDK (parent of Demo folder)
SDK_PATH="../../"

echo "📦 SDK Path: $SDK_PATH"

# Open Xcode project
echo "📱 Opening Xcode..."
open tv2demo.xcodeproj

echo ""
echo "✅ Xcode opened!"
echo ""
echo "📋 Manual Steps:"
echo "1. In Xcode, select the 'tv2demo' project in the navigator"
echo "2. Select the 'tv2demo' target"
echo "3. Go to 'General' tab"
echo "4. Scroll to 'Frameworks, Libraries, and Embedded Content'"
echo "5. Click the '+' button"
echo "6. Click 'Add Other...' → 'Add Package Dependency...'"
echo "7. Click 'Add Local...'"
echo "8. Navigate to: /Users/angelo/ReachuSwiftSDK"
echo "9. Click 'Add Package'"
echo "10. Select 'ReachuComplete' (or individual modules)"
echo "11. Click 'Add Package'"
echo ""
echo "OR use this path directly:"
echo "/Users/angelo/ReachuSwiftSDK"
echo ""
echo "🎯 Recommended: Select 'ReachuComplete' for full functionality"


