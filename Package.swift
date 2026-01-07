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
    dependencies: [
        .package(url: "https://github.com/soulverteam/SoulverCore", from: "3.3.0")
    ],
    targets: [
        .executableTarget(
            name: "SlashRemind",
            dependencies: [
                .product(name: "SoulverCore", package: "SoulverCore")
            ],
            path: ".",
            exclude: [
                "README.md", ".gitignore", "Resources", "Tests", "CLAUDE.md", "Info.plist",
                "AGENTS.md", "Makefile", "plan-logging.md",
                "App/CLAUDE.md", "StatusBar/CLAUDE.md", "Palette/CLAUDE.md", "Palette/README.md",
                "Services/CLAUDE.md", "Services/README.md", "ViewModels/CLAUDE.md",
                "Preferences/CLAUDE.md", "Utilities/CLAUDE.md"
            ],
            sources: ["App", "StatusBar", "Palette", "Services", "ViewModels", "Preferences", "Utilities"]
        ),
        .testTarget(
            name: "SlashRemindTests",
            dependencies: ["SlashRemind"],
            path: "Tests",
            exclude: ["CLAUDE.md"]
        )
    ]
)
