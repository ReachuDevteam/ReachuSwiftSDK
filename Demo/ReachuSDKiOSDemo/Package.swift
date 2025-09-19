// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReachuSDKiOSDemo",
    platforms: [
        .iOS(.v15),
        .macOS(.v12) // Required for SPM compatibility, but app is iOS-only
    ],
    products: [
        .library(
            name: "ReachuSDKiOSDemo",
            targets: ["ReachuSDKiOSDemo"]
        ),
    ],
    dependencies: [
        // Referencia local al SDK
        .package(path: "../../"),
    ],
    targets: [
        .target(
            name: "ReachuSDKiOSDemo",
            dependencies: [
                .product(name: "ReachuDesignSystem", package: "ReachuSwiftSDK"),
                .product(name: "ReachuCore", package: "ReachuSwiftSDK"),
            ],
            path: "Sources/ReachuSDKiOSDemo",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ReachuSDKiOSDemoTests",
            dependencies: ["ReachuSDKiOSDemo"],
            path: "Tests/ReachuSDKiOSDemoTests"
        ),
    ]
)
