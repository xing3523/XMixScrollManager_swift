// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XMixScrollManager",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "XMixScrollManager",
            targets: ["XMixScrollManager"]),
    ],
    targets: [
        .target(
            name: "XMixScrollManager",
            dependencies: [],
            path: "Sources",
            sources: ["XMixScrollManager"]
        )
    ]
)
