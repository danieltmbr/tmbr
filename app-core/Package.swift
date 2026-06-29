// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "app-core",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        // Shared across all three apps (Author / Reader / Personal).
        // Imports AppApi for RequestLoader types; per-app config (baseURL/auth/store) is injected
        // at the app layer via env values — AppCore never constructs URLSession or AuthProvider.
        // See .claude/docs/native-apps-architecture.md.
        .library(name: "AppCore", targets: ["AppCore"]),
    ],
    dependencies: [
        .package(path: "../tmbr-core"),
        .package(path: "../app-api"),
        .package(path: "../app-persistence"),
    ],
    targets: [
        .target(
            name: "AppCore",
            dependencies: [
                .product(name: "TmbrCore", package: "tmbr-core"),
                .product(name: "AppApi", package: "app-api"),
                .product(name: "AppPersistence", package: "app-persistence"),
            ]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: ["AppCore"]
        ),
    ]
)
