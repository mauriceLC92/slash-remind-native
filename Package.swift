// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SlashRemind",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SlashRemind", targets: ["SlashRemind"])
    ],
    targets: [
        .executableTarget(
            name: "SlashRemind",
            path: ".",
            exclude: ["README.md", ".gitignore", "Resources", "Tests", "CLAUDE.md"],
            sources: ["App", "StatusBar", "Palette", "Services", "ViewModels", "Preferences", "Utilities"]
        ),
        .testTarget(
            name: "SlashRemindTests",
            dependencies: ["SlashRemind"],
            path: "Tests"
        )
    ]
)
