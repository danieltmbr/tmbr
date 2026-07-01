// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "tmbr-web",
    platforms: [
       .macOS(.v15)
    ],
    dependencies: [
        // 🍎 Shared types for native app and backend.
        .package(path: "../tmbr-core"),
        // 🧩 Shared web infrastructure (Vapor/Fluent/Markdown helpers).
        .package(path: "../web-core"),
        // 🔐 Authentication + permissions.
        .package(path: "../web-auth"),
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
        .executableTarget(
            name: "Backend",
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
                .product(name: "TmbrCore", package: "tmbr-core"),
                .product(name: "WebCore", package: "web-core"),
                .product(name: "WebAuth", package: "web-auth"),
            ],
            path: "Sources/App",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "Backend"),
                .product(name: "WebAuth", package: "web-auth"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v5]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableExperimentalFeature("StrictConcurrency"),
] }
