// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "MeterReporter",
    platforms: [.macOS(.v10_13), .iOS(.v12), .tvOS(.v12), .watchOS(.v3)],
    products: [
        .library(name: "MeterReporter", targets: ["MeterReporter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/Meter", .branch("main")),
        .package(url: "https://github.com/ChimeHQ/Wells", .branch("main")),
    ],
    targets: [
        .target(name: "MeterReporter", dependencies: ["Meter"]),
    ]
)
