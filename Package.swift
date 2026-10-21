// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SlideToConfirm",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SlideToConfirm", targets: ["SlideToConfirm"]),
    ],
    targets: [
        .target(
            name: "SlideToConfirm",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "SlideToConfirmTests",
            dependencies: ["SlideToConfirm"]
        ),
    ]
)
