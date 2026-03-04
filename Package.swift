// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrivateKitchenApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
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
                // 添加资源文件，如果有的话
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ]
        )
    ]
)