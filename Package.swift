// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SlashRemind",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "SlashRemind", targets: ["SlashRemind"])
    ],
    targets: [
        .target(
            name: "SlashRemind",
            path: ".",
            exclude: ["README.md", ".gitignore", "Resources", "Tests"],
            sources: ["App", "StatusBar", "Palette", "Services", "ViewModels", "Preferences", "Utilities"]
        ),
        .testTarget(
            name: "SlashRemindTests",
            dependencies: ["SlashRemind"],
            path: "Tests"
        )
    ]
)
