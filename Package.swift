// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MeterReporter",
    platforms: [.macOS(.v11), .iOS(.v12), .tvOS(.v12), .watchOS(.v3)],
    products: [
        .library(name: "MeterReporter", targets: ["MeterReporter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ChimeHQ/Meter", from: "0.4.0"),
        .package(url: "https://github.com/ChimeHQ/Wells", from: "0.3.0"),
    ],
    targets: [
        .target(name: "MeterReporter", dependencies: ["Meter", "Wells"]),
    ]
)
