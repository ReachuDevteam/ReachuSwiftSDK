# 🔧 SDK Dependency Fix for ReachuDemoApp

## Problem

When you have multiple demo apps in the same repository as the SDK, each app needs to correctly reference the SDK as a local package.

### Error Messages
```
Missing package product 'ReachuUI'
Missing package product 'ReachuLiveUI'
Missing package product 'ReachuDesignSystem'
Missing package product 'ReachuLiveShow'
```

## Root Cause

The project was configured with an incorrect relative path to the SDK:
```
Path: ../../../ReachuSwiftSDK  ❌ WRONG
```

This path goes too far up and doesn't point to the actual SDK root.

## Solution Applied ✅

**Correct relative path:**
```
Path: ../..  ✅ CORRECT
```

### Directory Structure
```
ReachuSwiftSDK/              ← SDK root (Package.swift is here)
├── Package.swift
├── Sources/
│   ├── ReachuCore/
│   ├── ReachuUI/
│   ├── ReachuDesignSystem/
│   ├── ReachuLiveShow/
│   └── ReachuLiveUI/
└── Demo/
    ├── ReachuDemoApp/       ← We are here
    │   └── ReachuDemoApp.xcodeproj
    └── tv2demo/
        └── tv2demo.xcodeproj
```

From `ReachuDemoApp/`, we need to go up 2 levels (`../..`) to reach the SDK root.

## What Was Fixed

1. ✅ Updated `project.pbxproj` with correct relative path
2. ✅ Removed `Package.resolved` to force re-resolution
3. ✅ Created `fix-sdk-dependency.sh` script for future use

## Next Steps

### In Xcode:

1. **Open the project:**
   ```bash
   open ReachuDemoApp.xcodeproj
   ```

2. **Wait for Xcode to resolve dependencies** (may take a moment)

3. **If packages don't resolve automatically:**
   - Go to `File → Packages → Reset Package Caches`
   - Then `File → Packages → Update to Latest Package Versions`

4. **Verify the SDK products are now available:**
   - In Project Navigator → Frameworks
   - You should see all SDK modules

## Available SDK Products

After fixing, these products should be available:

| Product | Description |
|---------|-------------|
| `ReachuCore` | Core functionality (required) |
| `ReachuUI` | UI Components |
| `ReachuDesignSystem` | Design system components |
| `ReachuLiveShow` | Live show functionality |
| `ReachuLiveUI` | Live show UI components |

## For Other Demo Apps

If you encounter the same issue with another demo app (like `tv2demo`), use the same fix:

```bash
cd Demo/YOUR_DEMO_APP/
./fix-sdk-dependency.sh
```

Or manually:
1. Open `project.pbxproj` in a text editor
2. Find `XCLocalSwiftPackageReference`
3. Change `relativePath` to `../..`
4. Save and delete `Package.resolved`
5. Open in Xcode

## Prevention

When creating a new demo app in this repo:

1. In Xcode: `File → Add Package Dependencies`
2. Click "Add Local..."
3. Navigate to the **repository root** (where `Package.swift` is)
4. Select the SDK root folder
5. Xcode will automatically use the correct relative path

## Troubleshooting

### Still seeing "Missing package product" errors?

**Option 1: Reset Package Caches**
```bash
cd /Users/angelo/ReachuSwiftSDK
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf Demo/ReachuDemoApp/ReachuDemoApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/
```

**Option 2: Remove and Re-add Package**
1. In Xcode Project Navigator → Project → Package Dependencies
2. Select "ReachuSwiftSDK" and click "-" to remove
3. Click "+" and add it again as a local package

**Option 3: Clean Build**
```
Product → Clean Build Folder (⌘⇧K)
```

### Package shows but products are missing?

Check `Package.swift` in the SDK root to ensure all products are defined:
```swift
products: [
    .library(name: "ReachuCore", targets: ["ReachuCore"]),
    .library(name: "ReachuUI", targets: ["ReachuCore", "ReachuUI"]),
    // ... etc
]
```

## Related Files

- `fix-sdk-dependency.sh` - Script to automatically fix the path
- `Package.swift` (in repo root) - SDK package definition
- `project.pbxproj` - Xcode project file with package references

