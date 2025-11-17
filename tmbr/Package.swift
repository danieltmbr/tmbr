// swift-tools-version:6.0.3
import PackageDescription

let package = Package(
    name: "tmbr",
    platforms: [
       .macOS(.v15)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "CoreWeb", targets: ["CoreWeb"]),
        .library(name: "AuthKit", targets: ["AuthKit"]),
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🍃 An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        // 🚦 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // 🔑 JWT library for token verification.
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
        // 🖋️ Markdown parser
        .package(url: "https://github.com/danieltmbr/swift-markdown.git", branch: "main"),
        // 🔔 Push notifications
        .package(url: "https://github.com/mochidev/swift-webpush.git", from: "0.4.1"),
        // 🖼️ File storage for gallery
        .package(url: "https://github.com/soto-project/soto.git", from: "7.9.0"),
        // 🔏 CryptoKit substitution for Linux
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.7.0"),
        // 📏 Resize images
        .package(url: "https://github.com/danieltmbr/ImageResize.git", from: "1.0.1"),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .target(
            name: "CoreWeb",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .target(
            name: "AuthKit",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "JWT", package: "jwt"),
            ]
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "WebPush", package: "swift-webpush"),
                .product(name: "SotoS3", package: "soto"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "ImageResize", package: "ImageResize"),
                "Core",
                "CoreWeb",
                "AuthKit",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
    .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
] }
