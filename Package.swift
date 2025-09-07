// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ToyBrowser",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/migueldeicaza/SkiaKit.git", branch: "main"),
        .package(url: "https://github.com/ctreffs/SwiftSDL2.git", from: "1.4.1"),
        .package(url: "https://github.com/Kitura/BlueSocket.git", from: "2.0.4"),
        .package(url: "https://github.com/Kitura/BlueSSLService.git", from: "2.0.2"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ToyBrowser",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SkiaKit", package: "SkiaKit"),
                .product(name: "SDL", package: "SwiftSDL2"),
                .product(name: "Socket", package: "BlueSocket"),
                .product(name: "SSLService", package: "BlueSSLService"),
            ]
        ),
    ]
)
