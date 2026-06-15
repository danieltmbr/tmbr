// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "app-core",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        // Shared across all three apps (Author / Reader / Personal).
        // MUST NOT depend on networking (ApiKit/URLSession) or CloudKit — per-app sync is
        // injected at the app layer as closures. See .claude/docs/native-apps-architecture.md.
        .library(name: "AppCore", targets: ["AppCore"]),
        // Networking foundation (request loaders + pagination driver) for the backend-wired apps
        // (Author + Reader). Personal does NOT link this — it is CloudKit-only.
        .library(name: "AppBackend", targets: ["AppBackend"]),
    ],
    dependencies: [
        .package(path: "../tmbr-core"),
        .package(path: "../api-kit"),
    ],
    targets: [
        .target(
            name: "AppCore",
            dependencies: [.product(name: "TmbrCore", package: "tmbr-core")]
        ),
        .target(
            name: "AppBackend",
            dependencies: [
                .product(name: "TmbrCore", package: "tmbr-core"),
                .product(name: "ApiKit", package: "api-kit"),
            ]
        ),
    ]
)
