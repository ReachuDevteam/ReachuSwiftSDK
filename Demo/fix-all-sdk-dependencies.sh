#!/bin/bash

# Script to fix SDK dependencies for ALL demo projects
# This removes and re-adds the local package reference

set -e

SDK_ROOT="/Users/angelo/ReachuSwiftSDK"
DEMOS=("tv2demo" "ReachuDemoApp")

echo "🔧 Fixing SDK dependencies for all demo projects..."
echo "📁 SDK Root: $SDK_ROOT"
echo ""

# Kill Xcode to prevent conflicts
echo "🛑 Closing Xcode..."
killall Xcode 2>/dev/null || true
sleep 2

for DEMO in "${DEMOS[@]}"; do
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Processing: $DEMO"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    DEMO_DIR="$SDK_ROOT/Demo/$DEMO"
    
    if [ ! -d "$DEMO_DIR" ]; then
        echo "⚠️  Directory not found: $DEMO_DIR"
        continue
    fi
    
    cd "$DEMO_DIR"
    
    # Find the project file
    PROJECT_FILE=$(find . -maxdepth 2 -name "*.xcodeproj" -type d | head -1)
    
    if [ -z "$PROJECT_FILE" ]; then
        echo "❌ No .xcodeproj found in $DEMO_DIR"
        continue
    fi
    
    PROJECT_NAME=$(basename "$PROJECT_FILE" .xcodeproj)
    PBXPROJ="$PROJECT_FILE/project.pbxproj"
    
    echo "📝 Project: $PROJECT_NAME"
    echo "📄 File: $PBXPROJ"
    
    # Backup
    cp "$PBXPROJ" "$PBXPROJ.backup"
    echo "✅ Backup created"
    
    # Fix the relative path
    sed -i '' 's|relativePath = ../../../ReachuSwiftSDK;|relativePath = ../..;|g' "$PBXPROJ"
    sed -i '' 's|relativePath = ../../ReachuSwiftSDK;|relativePath = ../..;|g' "$PBXPROJ"
    echo "✅ Fixed relative path to: ../.."
    
    # Remove Package.resolved
    PKG_RESOLVED="$PROJECT_FILE/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    if [ -f "$PKG_RESOLVED" ]; then
        rm "$PKG_RESOLVED"
        echo "✅ Removed Package.resolved"
    fi
    
    # Remove all SPM caches for this project
    rm -rf "$PROJECT_FILE/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    rm -rf ".build"
    echo "✅ Cleared local caches"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧹 Cleaning global Xcode caches..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Clean global caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ Global caches cleaned"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL DONE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Open your project in Xcode"
echo "2. Wait for package resolution (may take 1-2 minutes)"
echo "3. If still failing:"
echo "   - Go to File → Packages → Reset Package Caches"
echo "   - Go to File → Packages → Resolve Package Versions"
echo ""
echo "If the problem persists, try manually removing the package:"
echo "   Project → Package Dependencies → Select SDK → Remove (-)"
echo "   Then add it back: + → Add Local → Navigate to: $SDK_ROOT"
echo ""

