//
// SchemaExample.swift
//
// Created by Andreas in 2020
//

import Foundation
import Vapor
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

    public let data: (Configuration, Location) -> Data?

    public enum Location {
        case header, body, path
    }

    public enum SchemaExampleError: Error {
        case couldNotCreateData
    }

    private static func data<T: Codable>(example: T, configuration: Configuration, location: Location) -> Data? {
        switch location {
        case .header, .body:
            return configuration.encode(example: example)
        case .path:
            guard let encoder = try? configuration.contentConfiguration.requireURLEncoder() else {
                return nil
            }
            var uri = URI()
            try? encoder.encode(example, to: &uri)
            return uri.query.map { Data($0.utf8) }
        }
    }

    func value<T: Decodable>(for type: T.Type, configuration: Configuration, location: Location) throws -> T {
        guard let data = self.data(configuration, location)
        else { throw SchemaExampleError.couldNotCreateData }
        let value = try configuration.bodyDecoder.decode(T.self, from: .init(data: data), headers: .init())
        if !allowOptional && value is ExpressibleByNilLiteral {
            throw SchemaExampleError.couldNotCreateData
        }
        return value
    }
}
