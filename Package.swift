// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReachuSwiftSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        // Core product - always needed (FASE 1)
        .library(
            name: "ReachuCore",
            targets: ["ReachuCore"]
        ),
        
        // Network module - internal shared networking (FASE 1)
        .library(
            name: "ReachuNetwork",
            targets: ["ReachuNetwork"]
        ),
        
        // UI Components - optional target (FASE 2)
        .library(
            name: "ReachuUI",
            targets: ["ReachuCore", "ReachuUI"]
        ),
        
        // Design System - internal UI shared components (FASE 2)
        .library(
            name: "ReachuDesignSystem",
            targets: ["ReachuDesignSystem"]
        ),
        
        // LiveShow - optional target (FASE 3)
        .library(
            name: "ReachuLiveShow",
            targets: ["ReachuCore", "ReachuLiveShow"]
        ),
        
        // Testing utilities - internal testing helpers
        .library(
            name: "ReachuTesting",
            targets: ["ReachuTesting"]
        ),
        
        // Complete SDK - everything included
        .library(
            name: "ReachuComplete",
            targets: ["ReachuCore", "ReachuUI", "ReachuLiveShow", "ReachuLiveUI"]
        ),
        
    ],
    dependencies: [
        // GraphQL client for Reachu API
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.0.0"),
        
        // WebSocket for LiveShow real-time features
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
        
        // Image caching for UI components
        .package(url: "https://github.com/kean/Nuke.git", from: "12.0.0"),
    ],
    targets: [
        // MARK: - INTERNAL: Network Target (Shared)
        .target(
            name: "ReachuNetwork",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios"),
            ],
            path: "Sources/ReachuNetwork"
        ),
        
        // MARK: - FASE 1: Core Target (Required)
        .target(
            name: "ReachuCore",
            dependencies: [
                "ReachuNetwork",
            ],
            path: "Sources/ReachuCore"
        ),
        
        // MARK: - INTERNAL: Design System Target (Shared)
        .target(
            name: "ReachuDesignSystem",
            dependencies: [
                "ReachuCore",
                .product(name: "Nuke", package: "Nuke"),
            ],
            path: "Sources/ReachuDesignSystem"
        ),
        
        // MARK: - FASE 2: UI Components Target (Optional)
        .target(
            name: "ReachuUI",
            dependencies: [
                "ReachuCore",
                "ReachuDesignSystem",
                "ReachuTesting", // For previews and mock data
            ],
            path: "Sources/ReachuUI"
        ),
        
        // MARK: - FASE 3: LiveShow Target (Optional)
        .target(
            name: "ReachuLiveShow",
            dependencies: [
                "ReachuCore",
                "ReachuNetwork",
                .product(name: "Starscream", package: "Starscream"),
            ],
            path: "Sources/ReachuLiveShow"
        ),
        
        // MARK: - FASE 3: LiveShow UI Target (Optional)
        .target(
            name: "ReachuLiveUI",
            dependencies: [
                "ReachuCore",
                "ReachuLiveShow",
                "ReachuUI",
                "ReachuDesignSystem",
            ],
            path: "Sources/ReachuLiveUI"
        ),
        
        // MARK: - INTERNAL: Testing Utilities Target
        .target(
            name: "ReachuTesting",
            dependencies: [
                "ReachuCore",
                "ReachuNetwork",
            ],
            path: "Sources/ReachuTesting"
        ),
        
        
        // MARK: - Test Targets (TODO: Create test directories)
        // Tests temporarily removed until directories are created
    ]
)
