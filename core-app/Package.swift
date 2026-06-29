// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "core-app",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        // Shared across all three apps (Author / Reader / Personal).
        // Imports CoreApi for RequestLoader types; per-app config (baseURL/auth/store) is injected
        // at the app layer via env values — CoreApp never constructs URLSession or AuthProvider.
        // Long-term: split CorePersistence (SwiftData @Model records + Stores) into its own target
        // so persistence is testable without SwiftUI. Do the split when a second consumer exists.
        // See .claude/docs/native-apps-architecture.md.
        .library(name: "CoreApp", targets: ["CoreApp"]),
    ],
    dependencies: [
        .package(path: "../core-tmbr"),
        .package(path: "../core-api"),
    ],
    targets: [
        .target(
            name: "CoreApp",
            dependencies: [
                .product(name: "CoreTmbr", package: "core-tmbr"),
                .product(name: "CoreApi", package: "core-api"),
            ]
        ),
        .testTarget(
            name: "CoreAppTests",
            dependencies: ["CoreApp"]
        ),
    ]
)
