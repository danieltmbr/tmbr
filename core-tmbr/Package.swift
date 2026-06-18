// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "core-tmbr",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "CoreTmbr", targets: ["CoreTmbr"]),
    ],
    targets: [
        .target(name: "CoreTmbr"),
    ]
)
