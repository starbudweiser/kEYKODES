// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "kEYKODES",
    platforms: [.macOS(.v15)],
    targets: [
        // Tables, calcul des codes et traductions, sans interface (testable seul)
        .target(name: "KeyCore"),
        .executableTarget(name: "kEYKODES", dependencies: ["KeyCore"]),
        .testTarget(name: "KeyCoreTests", dependencies: ["KeyCore"], resources: [.copy("golden.json")]),
    ],
    swiftLanguageModes: [.v5]
)
