//
// TestDecoder.swift
//
// Created by Andreas in 2020
//

import Foundation

class TestDecoder: Decoder, SchemaObjectDelegate {

    let configuration: Configuration
    var objectStack: [Any.Type]
    var schemas: Ref<[String: SchemaObject]>
    var values: [String: Any]

    init(_ configuration: Configuration, delegate: SchemaObjectDelegate?) {
        self.configuration = configuration
        self.objectStack = delegate?.objectStack ?? []
        self.schemas = delegate?.schemas ?? .init([:])
        self.values = delegate?.values ?? [:]
    }

    enum DecoderError: Error {
        case recursion(SchemaProperties)
    }

    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]

    var schemaObject = SchemaObject()
    var isSingleValueOptional: Bool = false

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let testKeyedDecodingContainer = TestKeyedDecodingContainer<Key>(configuration)
        testKeyedDecodingContainer.delegate = self
        return KeyedDecodingContainer(testKeyedDecodingContainer)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        schemaObject.type = .array
        let testUnkeyedDecodingContainer = TestUnkeyedDecodingContainer(configuration)
        testUnkeyedDecodingContainer.delegate = self
        return testUnkeyedDecodingContainer
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        let testSingleValueDecodingContainer = TestSingleValueDecodingContainer(configuration)
        testSingleValueDecodingContainer.delegate = self
        return testSingleValueDecodingContainer
    }
}
