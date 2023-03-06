// swift-tools-version:5.7

import PackageDescription

public let package = Package(
    name: "HighlightedTextEditor",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "HighlightedTextEditor",
            targets: ["HighlightedTextEditor"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/symbiose-technologies/NextGrowingTextView", branch: "symbiose")
    ],
    targets: [
        .target(
            name: "HighlightedTextEditor",
            dependencies: [
                .product(name: "NextGrowingTextView", package: "NextGrowingTextView")
            ]
        )
    ]
)

