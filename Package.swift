// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vapor-openapi",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "VaporOpenAPI", targets: ["VaporOpenAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "VaporOpenAPI",
            dependencies: [.product(name: "Vapor", package: "vapor")]
        ),
        .testTarget(
            name: "vapor-openapiTests",
            dependencies: ["VaporOpenAPI"]
        ),
    ]
)
