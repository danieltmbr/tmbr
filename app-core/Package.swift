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
    ],
    dependencies: [
        .package(path: "../tmbr-core"),
    ],
    targets: [
        .target(
            name: "AppCore",
            dependencies: [.product(name: "TmbrCore", package: "tmbr-core")]
        ),
    ]
)
