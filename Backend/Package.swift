// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShadowFilesServer",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.0")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [.product(name: "Vapor", package: "vapor")]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [.target(name: "App")]
        )
    ]
)
