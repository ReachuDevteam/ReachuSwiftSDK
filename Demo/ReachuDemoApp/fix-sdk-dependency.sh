#!/bin/bash

# Script to fix SDK dependency path in ReachuDemoApp
# This script updates the local package reference to point to the correct SDK location

set -e

PROJECT_FILE="ReachuDemoApp.xcodeproj/project.pbxproj"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd "$SCRIPT_DIR"

echo "🔧 Fixing SDK dependency path in ReachuDemoApp..."
echo "📁 Working directory: $SCRIPT_DIR"

# Backup the project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"
echo "✅ Backup created: $PROJECT_FILE.backup"

# Fix the incorrect path reference
# From: "../../../ReachuSwiftSDK" or "../../ReachuSwiftSDK" (wrong)
# To: "../.." (correct - points to repo root where Package.swift is)

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's|relativePath = ../../../ReachuSwiftSDK;|relativePath = ../..;|g' "$PROJECT_FILE"
    sed -i '' 's|relativePath = ../../ReachuSwiftSDK;|relativePath = ../..;|g' "$PROJECT_FILE"
else
    # Linux
    sed -i 's|relativePath = ../../../ReachuSwiftSDK;|relativePath = ../..;|g' "$PROJECT_FILE"
    sed -i 's|relativePath = ../../ReachuSwiftSDK;|relativePath = ../..;|g' "$PROJECT_FILE"
fi

echo "✅ Fixed package reference path"

# Remove Package.resolved to force Xcode to resolve dependencies again
if [ -f "ReachuDemoApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]; then
    rm "ReachuDemoApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    echo "✅ Removed old Package.resolved"
fi

echo ""
echo "✅ Done! Next steps:"
echo "1. Open ReachuDemoApp.xcodeproj in Xcode"
echo "2. Xcode will automatically resolve the SDK dependencies"
echo "3. If needed, go to File → Packages → Reset Package Caches"
echo ""
echo "The SDK products should now be available:"
echo "  - ReachuCore"
echo "  - ReachuUI"
echo "  - ReachuDesignSystem"
echo "  - ReachuLiveShow"
echo "  - ReachuLiveUI"

