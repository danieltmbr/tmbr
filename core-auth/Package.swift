// swift-tools-version:6.0.3
import PackageDescription

let package = Package(
    name: "core-auth",
    platforms: [
       .macOS(.v15)
    ],
    products: [
        .library(name: "CoreAuth", targets: ["CoreAuth"]),
    ],
    dependencies: [
        // 🍎 Shared types for native app and backend.
        .package(path: "../core-tmbr"),
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
        // 🗄 An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        // 🐘 Fluent driver for Postgres.
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        // 🔑 JWT library for token verification.
        .package(url: "https://github.com/vapor/jwt.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "CoreAuth",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "JWT", package: "jwt"),
                .product(name: "CoreTmbr", package: "core-tmbr"),
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
