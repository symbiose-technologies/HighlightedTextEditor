// swift-tools-version:5.3

import PackageDescription

public let package = Package(
    name: "HighlightedTextEditor",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "HighlightedTextEditor",
            targets: ["HighlightedTextEditor"]
        )
    ],
    targets: [
        .target(
            name: "HighlightedTextEditor",
            dependencies: []
        )
    ]
)

if #available(iOS 15.0, *) {
    package.dependencies.append(.package(url: "https://github.com/FluidGroup/NextGrowingTextView",
                                         from: "2.2.1"))
    package.targets[0] = .target(
        name: "HighlightedTextEditor",
        dependencies: ["NextGrowingTextView"]
    )
}

