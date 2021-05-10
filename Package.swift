// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "feather-sdk",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "FeatherApi", targets: ["FeatherApi"]),
        .library(name: "FeatherClient", targets: ["FeatherClient"]),
    ],
    targets: [
        .target(name: "FeatherApi"),
        .target(name: "FeatherClient", dependencies: [
            .target(name: "FeatherApi"),
        ]),
        .testTarget(name: "FeatherClientTests", dependencies: [
            .target(name: "FeatherClient"),
        ])
    ]
)
