// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DemoApp",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "DemoApp",
            targets: ["DemoApp"]
        ),
        .library(
            name: "DemoAppLib",
            targets: ["DemoAppLib"]
        ),
    ],
    dependencies: [
        // Referencia local al SDK que estás desarrollando
        .package(path: "../../"),
    ],
    targets: [
        .target(
            name: "DemoAppLib",
            dependencies: [
                .product(name: "ReachuDesignSystem", package: "ReachuSwiftSDK"),
            ],
            path: "Sources/DemoAppLib"
        ),
        .executableTarget(
            name: "DemoApp",
            dependencies: [
                "DemoAppLib"
            ],
            path: "Sources/DemoApp"
        )
    ]
)
