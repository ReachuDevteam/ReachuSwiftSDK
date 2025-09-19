// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReachuSDKDemo",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ReachuSDKDemo",
            targets: ["ReachuSDKDemo"]
        ),
    ],
    dependencies: [
        // Referencia local al SDK que estás desarrollando
        .package(path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "ReachuSDKDemo",
            dependencies: [
                .product(name: "ReachuDesignSystem", package: "ReachuSwiftSDK"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImportObjcForwardDeclarations"),
                .enableUpcomingFeature("DisableOutwardActorInference"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        )
    ]
)
