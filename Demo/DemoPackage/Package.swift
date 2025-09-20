// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DemoPackage",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .executable(
            name: "ReachuDemo",
            targets: ["ReachuDemo"]
        ),
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "ReachuDemo",
            dependencies: [
                .product(name: "ReachuCore", package: "ReachuSwiftSDK"),
                .product(name: "ReachuUI", package: "ReachuSwiftSDK"),
                .product(name: "ReachuDesignSystem", package: "ReachuSwiftSDK"),
                .product(name: "ReachuTesting", package: "ReachuSwiftSDK"),
            ],
            path: "Sources"
        ),
    ]
)
