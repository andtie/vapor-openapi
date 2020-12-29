//
// Inferrable.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

protocol Inferrable {
    static func inferSchema(with configuration: CoderConfig, delegate: SchemaObjectDelegate?) throws -> SchemaObject
    static func inferValue(with configuration: CoderConfig, delegate: SchemaObjectDelegate?) throws -> Any
}

struct Container<V: Decodable> {}

extension Container: Inferrable where V: CaseIterable, V: RawRepresentable, V.RawValue: PrimitiveJSONType {
    static func inferSchema(with configuration: CoderConfig, delegate: SchemaObjectDelegate?) throws -> SchemaObject {
        let decoder = TestDecoder(configuration, delegate: delegate)
        _ = try V.RawValue(from: decoder)
        let schemaObject = decoder.schemaObject
        schemaObject.enum = V.allCases.map(\.rawValue).map(AnyPrimitiveJSONType.init(value:))
        return schemaObject
    }

    static func inferValue(with configuration: CoderConfig, delegate: SchemaObjectDelegate?) throws -> Any {
        guard let value = V.allCases.first else { fatalError("`Never` use this API ;-)") }
        return value
    }
}

extension Dictionary: Inferrable where Key == String, Value: Decodable {
    static func inferSchema(with configuration: CoderConfig, delegate: SchemaObjectDelegate?) throws -> SchemaObject {
        let decoder = TestDecoder(configuration, delegate: delegate)
        _ = try Value(from: decoder)
        let schemaObject = SchemaObject()
        schemaObject.additionalProperties = decoder.schemaObject
        return schemaObject
    }

    static func inferValue(with configuration: CoderConfig, delegate: SchemaObjectDelegate?) throws -> Any {
        [:]
    }
}
