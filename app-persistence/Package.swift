// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "app-persistence",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "AppPersistence", targets: ["AppPersistence"]),
    ],
    dependencies: [
        .package(path: "../tmbr-core"),
    ],
    targets: [
        .target(
            name: "AppPersistence",
            dependencies: [.product(name: "TmbrCore", package: "tmbr-core")]
        ),
    ]
)
