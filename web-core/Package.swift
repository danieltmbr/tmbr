// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "web-core",
    platforms: [
       .macOS(.v26)
    ],
    products: [
        .library(name: "WebCore", targets: ["WebCore"]),
    ],
    dependencies: [
        // 🍎 Shared types for native app and backend.
        .package(path: "../tmbr-core"),
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🖋️ Markdown parser
        .package(url: "https://github.com/danieltmbr/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "WebCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "TmbrCore", package: "tmbr-core"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "WebCoreTests",
            dependencies: [
                .target(name: "WebCore")
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
