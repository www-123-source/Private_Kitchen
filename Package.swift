// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrivateKitchenApp",
    platforms: [
        .iOS("14.0"),
        .macOS("10.15")
    ],
    products: [
        .executable(
            name: "PrivateKitchenApp",
            targets: ["PrivateKitchenApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PrivateKitchenApp",
            path: "PrivateKitchenApp",
            sources: [
                "main.swift",
                "Models",
                "Views",
                "Sources"
            ],
            resources: [
            ]
        )
    ]
)