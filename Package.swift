// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoltbotWidgetsCLI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "moltbot-widgets", targets: ["MoltbotWidgetsCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "MoltbotWidgetsCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: ".",
            sources: [
                "MoltbotWidgetsCLI",
                "Shared/WidgetConfig.swift",
                "Shared/WidgetConfigStore.swift",
                "Shared/WidgetResponse.swift",
                "Shared/WidgetFetcher.swift",
            ]
        ),
    ]
)
