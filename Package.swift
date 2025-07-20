// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RepoForge",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "RepoForge",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "RepoForgeTests",
            dependencies: ["RepoForge"]
        )
    ]
)
