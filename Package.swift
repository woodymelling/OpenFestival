// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenFestival",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "OpenFestivalParser", targets: ["OpenFestivalParser"]),
        .library(name: "OpenFestivalModels", targets: ["OpenFestivalModels"]),
        .library(name: "OpenFestivalViewer", targets: ["OpenFestivalViewer"]),
        .library(name: "OpenFestivalApp", targets: ["OpenFestivalApp"]),
        .library(name: "GitClient", targets: ["GitClient"]),
        .executable(name: "openfestival", targets: ["OpenFestivalCLI"])
    ],
    dependencies: [
        
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.11.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
        .package(url: "https://github.com/pointfreeco/swift-validated", from: "0.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-prelude", branch: "main"),

        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.4"),

        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro", from: "0.2.0"),
        .package(url: "https://github.com/lorenzofiamingo/swiftui-cached-async-image", from: "2.1.1"),
        .package(url: "https://github.com/ryohey/Zoomable", branch: "main"),
        .package(url: "https://github.com/bdewey/static-libgit2", from: "0.1.0"),
        .package(url: "https://github.com/bdewey/AsyncSwiftGit/", from: "0.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OpenFestivalParser",
            dependencies: [
                "Yams",
                "GitClient",
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Validated", package: "swift-validated"),
                .product(name: "Prelude", package: "swift-prelude"),
                .target(name: "OpenFestivalModels"),
            ]
        ),
        .target(
            name: "OpenFestivalModels",
            dependencies: [
                .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "MemberwiseInit", package: "swift-memberwise-init-macro"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Tagged", package: "swift-tagged")
            ]
        ),
        .target(
            name: "OpenFestivalViewer",
            dependencies: [
                "OpenFestivalModels",
                "OpenFestivalParser",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "CachedAsyncImage", package: "swiftui-cached-async-image"),
                .product(name: "Zoomable", package: "Zoomable"),
            ],
            resources: [
                .process("Media")
            ]
        ),
        .target(
            name: "GitClient",
            dependencies: [
                .product(name: "AsyncSwiftGit", package: "AsyncSwiftGit"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
            ]
        ),
        .target(
            name: "OpenFestivalApp",
            dependencies: [
                "OpenFestivalModels",
                "OpenFestivalParser",
                "OpenFestivalViewer",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "CachedAsyncImage", package: "swiftui-cached-async-image"),

            ]
        ),
        .executableTarget(
            name: "OpenFestivalCLI",
             dependencies: [
                "OpenFestivalParser",
                "GitClient",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Dependencies", package: "swift-dependencies")
            ]
        ),
        .testTarget(
            name: "OpenFestivalParserTests",
            dependencies: [
                 "OpenFestivalParser",
                 "Yams",
                 .product(name: "CustomDump", package: "swift-custom-dump"),
            ],
            resources: [
                .copy("ExampleFestivals")
            ]
        ),
    ]
)
