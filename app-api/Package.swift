// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "app-api",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "AppApi", targets: ["AppApi"]),
    ],
    dependencies: [
        .package(path: "../tmbr-core"),
    ],
    targets: [
        .target(
            name: "AppApi",
            dependencies: [.product(name: "TmbrCore", package: "tmbr-core")]
        ),
        .testTarget(name: "AppApiTests", dependencies: ["AppApi"]),
    ]
)
