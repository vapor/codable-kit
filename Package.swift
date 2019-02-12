// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "codable-kit",
    products: [
        .library(name: "CodableKit", targets: ["CodableKit"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "CodableKit", dependencies: []),
        .testTarget(name: "CodableKitTests", dependencies: ["CodableKit"]),
    ]
)
