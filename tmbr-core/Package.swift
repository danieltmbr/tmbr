// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "tmbr-core",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TmbrCore", targets: ["TmbrCore"]),
    ],
    targets: [
        .target(name: "TmbrCore"),
    ]
)
