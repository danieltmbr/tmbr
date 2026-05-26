// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "api-kit",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "ApiKit", targets: ["ApiKit"]),
    ],
    targets: [
        .target(name: "ApiKit"),
        .testTarget(name: "ApiKitTests", dependencies: ["ApiKit"]),
    ]
)
