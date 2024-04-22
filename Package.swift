// swift-tools-version:5.9

import PackageDescription

public let package = Package(
    name: "HighlightedTextEditor",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HighlightedTextEditor",
            targets: ["HighlightedTextEditor"]
        )
    ],
    dependencies: [
//        .package(url: "https://github.com/symbiose-technologies/NextGrowingTextView", branch: "symbiose"),
        .package(url: "https://github.com/symbiose-technologies/RSKGrowingTextView.git", branch: "symbiose")
    ],
    targets: [
        .target(
            name: "HighlightedTextEditor",
            dependencies: [
//                .product(name: "NextGrowingTextView", package: "NextGrowingTextView"),
                .product(name: "RSKGrowingTextView", package: "RSKGrowingTextView", condition: .when(platforms: [.iOS]))
            ]
        )
    ]
)

