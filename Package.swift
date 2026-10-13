// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PingBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PingBar",
            path: "Sources/PingBar"
        ),
        .testTarget(
            name: "PingBarTests",
            dependencies: ["PingBar"],
            path: "Tests/PingBarTests"
        ),
    ]
)
