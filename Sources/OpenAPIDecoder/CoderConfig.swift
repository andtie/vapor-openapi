//
// CoderConfig.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

public struct CoderConfig {

    public let coder: APICoderProtocol
    public var schemaExamples: [SchemaExample] = [
        SchemaExample(example: UUID(), for: SchemaObject(type: .string, format: .uuid)),
        SchemaExample(example: Date(), for: SchemaObject(type: .string, format: .dateTime)),
        SchemaExample(example: Data(), for: SchemaObject(type: .string, format: .byte))
    ]

    public init(coder: APICoderProtocol) {
        self.coder = coder
    }
}

public protocol APICoderProtocol {
    func encodeAsBody<T: Encodable>(example: T) -> Data?
    func encodeAsURL<T: Encodable>(example: T) -> Data?
    func decodeAsBody<T: Decodable>(data: Data) throws -> T
}
