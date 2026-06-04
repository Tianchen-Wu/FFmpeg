// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MediaForge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MediaForgeCore", targets: ["MediaForgeCore"]),
        .executable(name: "MediaForge", targets: ["MediaForge"])
    ],
    targets: [
        .target(name: "MediaForgeCore"),
        .executableTarget(
            name: "MediaForge",
            dependencies: ["MediaForgeCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MediaForgeCoreTests",
            dependencies: ["MediaForgeCore"]
        )
    ]
)
