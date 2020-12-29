//
// Configuration.swift
//
// Created by Andreas in 2020
//

import OpenAPI
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
            SchemaExample(example: UUID(), for: SchemaObject(type: .string, format: .uuid)),
            SchemaExample(example: Date(), for: SchemaObject(type: .string, format: .dateTime)),
            SchemaExample(example: Data(), for: SchemaObject(type: .string, format: .byte))
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

    public func encode<T: Codable>(example: T) -> Data? {
        guard let encoder = try? contentConfiguration.requireEncoder(for: .json) else {
            return nil
        }
        var headers = HTTPHeaders()
        var byteBuffer = ByteBuffer()
        try? encoder.encode(example, to: &byteBuffer, headers: &headers)
        return byteBuffer.getData(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
    }
}
