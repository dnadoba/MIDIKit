// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "MIDIKit",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "MIDIKit",
            targets: ["MIDIKit"]),
        .executable(
            name: "MIDIKitDemo",
            targets: ["MIDIKitDemo"]),
    ],
    targets: [
        .target(
            name: "MIDIKit",
            dependencies: []),
        .target(
            name: "MIDIKitDemo",
            dependencies: ["MIDIKit"]),
        .testTarget(
            name: "MIDIKitTests",
            dependencies: ["MIDIKit"]),
    ]
)
