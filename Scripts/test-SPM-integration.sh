#!/bin/bash

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

PROJECT_NAME=TempProject

# Clean up.
rm -rf $PROJECT_NAME

cleanup() {
    echo "Clean Up"
    cd ../
    rm -rf $PROJECT_NAME
}
trap cleanup EXIT

mkdir -p $PROJECT_NAME && cd $PROJECT_NAME

# Create the package.
swift package init

# Create the Package.swift.
echo "// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: \"TempProject\",
    defaultLocalization: \"en-US\",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: \"TempProject\",
            targets: [\"TempProject\"]
        )
    ],
    dependencies: [
        .package(name: \"AdyenNetworking\", path: \"../\")
    ],
    targets: [
        .target(
            name: \"TempProject\",
            dependencies: [
                .product(name: \"AdyenNetworking\", package: \"AdyenNetworking\")
            ]
        )
    ]
)
" > Package.swift


echo '############# swift package update ###############'
swift package update

# Build for generic iOS device
echo '############# Build for generic iOS device ###############'
xcodebuild build -scheme TempProject -destination 'generic/platform=iOS' -skipPackagePluginValidation -quiet -derivedDataPath ./.dd

# Archive for generic iOS device
echo '############# Archive for generic iOS device ###############'
xcodebuild clean build archive -scheme TempProject -destination 'generic/platform=iOS' -skipPackagePluginValidation -quiet -derivedDataPath ./.dd

# Build for x86_64 simulator
echo '############# Build for x86_64 simulator ###############'
xcodebuild build -scheme TempProject -destination 'generic/platform=iOS Simulator' ARCHS=x86_64 -skipPackagePluginValidation -quiet -derivedDataPath ./.dd

# Archive for x86_64 simulator
echo '############# Archive for x86_64 simulator ###############'
xcodebuild clean build archive -scheme TempProject -destination 'generic/platform=iOS Simulator' ARCHS=x86_64 -skipPackagePluginValidation -quiet -derivedDataPath ./.dd
