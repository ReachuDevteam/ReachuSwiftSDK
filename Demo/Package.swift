// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReachuDemo",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "ReachuDemo",
            targets: ["ReachuDemo"]
        ),
    ],
    dependencies: [
        .package(path: "../"),
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
            path: "ReachuDemoApp/ReachuDemoApp"
        ),
    ]
)
