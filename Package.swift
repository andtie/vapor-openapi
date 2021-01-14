// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vapor-openapi",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "VaporFaker", targets: ["VaporFaker"]),
        .library(name: "VaporOpenAPI", targets: ["VaporOpenAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/andtie/galactic-api-tools", from: "0.0.2")
    ],
    targets: [
        .target(
            name: "VaporFaker",
            dependencies: [
                .product(name: "OpenAPIFaker", package: "galactic-api-tools"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .target(
            name: "VaporOpenAPI",
            dependencies: [
                .product(name: "OpenAPI", package: "galactic-api-tools"),
                .product(name: "OpenAPIDecoder", package: "galactic-api-tools"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(
            name: "VaporTests",
            dependencies: ["VaporOpenAPI"]
        )
    ]
)
