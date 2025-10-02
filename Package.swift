// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReachuSwiftSDK",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
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

        // LiveShow UI Components - optional target (FASE 3)
        .library(
            name: "ReachuLiveUI",
            targets: ["ReachuCore", "ReachuLiveShow", "ReachuLiveUI"]
        ),

        // Complete SDK - everything included
        .library(
            name: "ReachuComplete",
            targets: ["ReachuCore", "ReachuDesignSystem", "ReachuUI", "ReachuLiveShow", "ReachuLiveUI"]
        ),

    ],
    dependencies: [
        // GraphQL client for Reachu API
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "1.0.0"),

        // WebSocket for LiveShow real-time features
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),

        // Image caching for UI components
        .package(url: "https://github.com/kean/Nuke.git", from: "12.0.0"),

        .package(url: "https://github.com/stripe/stripe-ios", .upToNextMajor(from: "24.24.1")),

    ],
    targets: [
        // MARK: - INTERNAL: Network Target (Shared)
        .target(
            name: "ReachuNetwork",
            dependencies: [
                .product(name: "Apollo", package: "apollo-ios")
            ],
            path: "Sources/ReachuNetwork"
        ),

        // MARK: - FASE 1: Core Target (Required)
        .target(
            name: "ReachuCore",
            dependencies: [
                "ReachuNetwork"
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
                "ReachuTesting",  // For previews and mock data
                .product(
                    name: "StripePaymentSheet", package: "stripe-ios",
                    condition: .when(platforms: [.iOS])),

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
        .target(
            name: "ReachuDemoKit",
            dependencies: [],
            path: "Demo/ReachuDemoSdk/Utils"
        ),
        // === DEMOS (ejecutables de consola) ===
        .executableTarget(
            name: "CartDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/CartDemo"
        ),
        .executableTarget(
            name: "ChannelDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/ChannelDemo",
            exclude: ["CategoryDemo", "InfoDemo", "ProductDemo"]
        ),
        .executableTarget(
            name: "CategoryDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/ChannelDemo/CategoryDemo"
        ),
        .executableTarget(
            name: "InfoDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/ChannelDemo/InfoDemo"
        ),
        .executableTarget(
            name: "ProductDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/ChannelDemo/ProductDemo"
        ),
        .executableTarget(
            name: "CheckoutDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/CheckoutDemo"
        ),
        .executableTarget(
            name: "DiscountDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/DiscountDemo"
        ),
        .executableTarget(
            name: "MarketDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/MarketDemo"
        ),
        .executableTarget(
            name: "PaymentDemo",
            dependencies: ["ReachuCore", "ReachuDemoKit"],
            path: "Demo/ReachuDemoSdk/PaymentDemo"
        ),
        .executableTarget(
            name: "SdkDemo",
            dependencies: [
                "ReachuCore", "ReachuDemoKit",
            ],
            path: "Demo/ReachuDemoSdk/Sdk"
        ),
        // MARK: - Test Targets (TODO: Create test directories)
        // Tests temporarily removed until directories are created
    ]
)
