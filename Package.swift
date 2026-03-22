// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HookHeroBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "HookHeroBar",
            path: "Sources/HookHeroBar"
        ),
    ]
)
