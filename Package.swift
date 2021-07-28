// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdyenNetworking",
    defaultLocalization: "en-us",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "AdyenNetworking",
            targets: ["AdyenNetworking"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AdyenNetworking",
            dependencies: [],
            path: "AdyenNetworking",
            exclude: [
                "Info.plist"
            ]
        )
    ]
)
