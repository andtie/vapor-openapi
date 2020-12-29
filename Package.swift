// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vapor-openapi",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "OpenAPI", targets: ["OpenAPI"]),
        .library(name: "OpenAPIDecoder", targets: ["OpenAPIDecoder"]),
        .library(name: "OpenAPIFaker", targets: ["OpenAPIFaker"]),
        .library(name: "VaporOpenAPI", targets: ["VaporOpenAPI"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "OpenAPI",
            dependencies: []
        ),
        .target(
            name: "OpenAPIDecoder",
            dependencies: [.target(name: "OpenAPI")]
        ),
        .target(
            name: "OpenAPIFaker",
            dependencies: [
                .target(name: "OpenAPI"),
                .target(name: "OpenAPIDecoder")
            ]
        ),
        .target(
            name: "VaporOpenAPI",
            dependencies: [
                .target(name: "OpenAPI"),
                .target(name: "OpenAPIDecoder"),
                .target(name: "OpenAPIFaker"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(
            name: "vapor-openapiTests",
            dependencies: ["VaporOpenAPI"]
        )
    ]
)
