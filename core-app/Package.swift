// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "core-app",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        // Shared across all three apps (Author / Reader / Personal).
        // MUST NOT depend on networking (CoreApi/URLSession) or CloudKit — per-app sync is
        // injected at the app layer as closures. See .claude/docs/native-apps-architecture.md.
        .library(name: "CoreApp", targets: ["CoreApp"]),
    ],
    dependencies: [
        .package(path: "../core-tmbr"),
    ],
    targets: [
        .target(
            name: "CoreApp",
            dependencies: [.product(name: "CoreTmbr", package: "core-tmbr")]
        ),
        .testTarget(
            name: "CoreAppTests",
            dependencies: ["CoreApp"]
        ),
    ]
)
