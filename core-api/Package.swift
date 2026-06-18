// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "core-api",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "CoreApi", targets: ["CoreApi"]),
    ],
    dependencies: [
        .package(path: "../core-tmbr"),
    ],
    targets: [
        .target(
            name: "CoreApi",
            dependencies: [.product(name: "CoreTmbr", package: "core-tmbr")]
        ),
        .testTarget(name: "CoreApiTests", dependencies: ["CoreApi"]),
    ]
)
