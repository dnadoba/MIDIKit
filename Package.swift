// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MIDIKit",
    platforms: [
        .macOS(.v10_14),
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "MIDIKit",
            targets: ["MIDIKit"]),
    ],
    targets: [
        .target(
            name: "MIDIKit",
            dependencies: []),
        .testTarget(
            name: "MIDIKitTests",
            dependencies: ["MIDIKit"]),
    ]
)
