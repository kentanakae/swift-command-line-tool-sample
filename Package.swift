// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftCommandLineToolSample",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .executable(name: "smp", targets: ["SwiftCommandLineToolSample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.1"),
        .package(url: "https://github.com/apple/swift-testing.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "SwiftCommandLineToolSample",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "SwiftCommandLineToolSampleTests",
            dependencies: [
                "SwiftCommandLineToolSample",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
