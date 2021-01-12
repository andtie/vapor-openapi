//
// TestDecoder.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

public class TestDecoder: Decoder, SchemaObjectDelegate {

    let configuration: CoderConfig
    public var objectStack: [Any.Type]
    public var schemas: Ref<[String: SchemaObject]>
    public var values: [String: Any]

    public init(_ configuration: CoderConfig, delegate: SchemaObjectDelegate?) {
        self.configuration = configuration
        self.objectStack = delegate?.objectStack ?? []
        self.schemas = delegate?.schemas ?? .init([:])
        self.values = delegate?.values ?? [:]
    }

    public enum DecoderError: Error {
        case recursion(SchemaProperties)
    }

    public var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public var schemaObject = SchemaObject()
    public var isSingleValueOptional: Bool = false

    public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let testKeyedDecodingContainer = TestKeyedDecodingContainer<Key>(configuration)
        testKeyedDecodingContainer.delegate = self
        return KeyedDecodingContainer(testKeyedDecodingContainer)
    }

    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        schemaObject.type = .array
        let testUnkeyedDecodingContainer = TestUnkeyedDecodingContainer(configuration)
        testUnkeyedDecodingContainer.delegate = self
        return testUnkeyedDecodingContainer
    }

    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        let testSingleValueDecodingContainer = TestSingleValueDecodingContainer(configuration)
        testSingleValueDecodingContainer.delegate = self
        return testSingleValueDecodingContainer
    }
}

extension TestDecoder {
    public func properties(for codable: Codable.Type, schemas: inout [String: SchemaObject]) throws -> SchemaProperties {
        do {
            _ = try codable.init(from: self)
        } catch TestDecoder.DecoderError.recursion {
            // noop
        } catch {
            throw error
        }
        let properties = SchemaProperties(type: codable)
        schemas[properties.name] = properties.isArray ? schemaObject.items : schemaObject
        for (key, value) in self.schemas.value {
            schemas[key] = value
        }
        return properties
    }
}
