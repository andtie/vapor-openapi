//
// SchemaExample.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

public struct SchemaExample {

    public let schema: SchemaObject
    public let allowOptional: Bool

    public init(data: Data, for schema: SchemaObject, allowOptional: Bool = false) {
        self.data = { _, _ in data }
        self.allowOptional = allowOptional
        self.schema = schema
    }

    public init<T: Codable>(example: T, for schema: SchemaObject) {
        self.schema = schema
        self.allowOptional = example is ExpressibleByNilLiteral
        self.data = { Self.data(example: example, configuration: $0, location: $1) }
    }

    public let data: (CoderConfig, Location) -> Data?

    public enum Location {
        case header, body, path
    }

    public enum SchemaExampleError: Error {
        case couldNotCreateData
    }

    private static func data<T: Codable>(example: T, configuration: CoderConfig, location: Location) -> Data? {
        switch location {
        case .header, .body:
            return configuration.coder.encodeAsBody(example: example)
        case .path:
            return configuration.coder.encodeAsURL(example: example)
        }
    }

    func value<T: Decodable>(for type: T.Type, configuration: CoderConfig, location: Location) throws -> T {
        guard let data = self.data(configuration, location)
        else { throw SchemaExampleError.couldNotCreateData }
        let value: T = try configuration.coder.decodeAsBody(data: data)
        if !allowOptional && value is ExpressibleByNilLiteral {
            throw SchemaExampleError.couldNotCreateData
        }
        return value
    }
}
