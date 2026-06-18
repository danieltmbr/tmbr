// swift-tools-version:6.0.3
import PackageDescription

let package = Package(
    name: "core-web",
    platforms: [
       .macOS(.v15)
    ],
    products: [
        .library(name: "CoreWeb", targets: ["CoreWeb"]),
    ],
    dependencies: [
        // 🍎 Shared types for native app and backend.
        .package(path: "../core-tmbr"),
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🖋️ Markdown parser
        .package(url: "https://github.com/danieltmbr/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "CoreWeb",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "CoreTmbr", package: "core-tmbr"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "CoreWebTests",
            dependencies: [
                .target(name: "CoreWeb")
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
    .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
] }
