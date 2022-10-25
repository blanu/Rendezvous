// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rendezvous",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Rendezvous",
            targets: ["Rendezvous"]),
        .library(
            name: "RendezvousClient",
            targets: [
                "RendezvousClient",
            ]
        ),
        .executable(
            name: "RendezvousServer",
            targets: [
                "RendezvousServer",
            ]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/OperatorFoundation/Abacus", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Chord", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Gardener", branch: "main"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle", from: "1.0.0-alpha.11"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/OperatorFoundation/Nametag", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Net", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Straw", branch: "main"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Rendezvous",
            dependencies: [
                "Abacus",
                "Nametag",
                "Net",
                "ShadowSwift",
            ]
        ),
        .target(
            name: "RendezvousClient",
            dependencies: [
                "Chord",
                "Rendezvous",
                "ShadowSwift",
                "Straw",
            ]
        ),
        .executableTarget(
            name: "RendezvousServer",
            dependencies: [
                "Gardener",
                .product(name: "Lifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                "Nametag",
                .product(name: "NIO", package: "swift-nio"),
                "Rendezvous",
            ]
        ),
        .testTarget(
            name: "RendezvousTests",
            dependencies: ["Rendezvous"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
