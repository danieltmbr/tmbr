// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "tmbr-core",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "TmbrCore", targets: ["TmbrCore"]),
    ],
    targets: [
        .target(name: "TmbrCore"),
    ]
)
