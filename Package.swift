// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "WebimMobileWidget",
    defaultLocalization: "ru",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "WebimMobileWidget",
            targets: ["WebimMobileWidget"]),
    ],
    dependencies: [
        .package(url: "https://github.com/webim/webim-client-sdk-ios.git", exact: "3.41.6"),
        .package(url: "https://github.com/kean/Nuke.git", from: "12.0.0"),
        .package(url: "https://github.com/evgenyneu/Cosmos.git", from: "25.0.1"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
        .package(url: "https://github.com/Flipboard/FLAnimatedImage.git", from: "1.0.17"),
        .package(url: "https://github.com/webim/webim-mobile-keyboard-ios.git", exact: "1.0.3")
    ],
    targets: [
        .target(
            name: "WebimMobileWidget",
            dependencies: [
                .product(name: "WebimMobileSDK", package: "webim-client-sdk-ios"),
                .product(name: "Nuke", package: "Nuke"),
                .product(name: "Cosmos", package: "Cosmos"),
                .product(name: "SnapKit", package: "SnapKit"),
                .product(name: "FLAnimatedImage", package: "FLAnimatedImage"),
                .product(name: "WebimKeyboard", package: "webim-mobile-keyboard-ios")
            ],
            path: "Sources",
            resources: [.copy("WebimMobileWidget/PrivacyInfo.xcprivacy")]
        )
    ]
)
