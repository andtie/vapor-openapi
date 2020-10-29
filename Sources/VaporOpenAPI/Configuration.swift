//
// Configuration.swift
//
// Created by Andreas in 2020
//

import Vapor

public struct Configuration {
    public var preProcessor: (Request) -> Void
    public var postProcessor: (inout OpenAPI) -> Void
    public var contentConfiguration: ContentConfiguration
    public var schemaExamples: [SchemaExample]

    public static var `default` = Configuration(
        preProcessor: { _ in },
        postProcessor: { _ in },
        contentConfiguration: .global,
        schemaExamples: [
            SchemaExample(example: UUID(), for: SchemaObject(type: .string)),
            SchemaExample(example: Date(), for: SchemaObject(type: .string, format: .dateTime)),
        ]
    )

    public var bodyDecoder: ContentDecoder {
        (try? contentConfiguration.requireDecoder(for: .json))
            ?? JSONDecoder.custom(dates: .iso8601)
    }


    public var urlLDecoder: URLQueryDecoder {
        (try? contentConfiguration.requireURLDecoder())
            ?? URLEncodedFormDecoder()
    }
}
