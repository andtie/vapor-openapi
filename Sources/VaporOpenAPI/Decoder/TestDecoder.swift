//
// TestDecoder.swift
//
// Created by Andreas in 2020
//

import Foundation

class TestDecoder: Decoder, SchemaObjectDelegate {

    let customStringTypeExamples: [String]

    init(_ customStringTypeExamples: [String]) {
        self.customStringTypeExamples = customStringTypeExamples
    }

    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey: Any] = [:]

    var schemaObject = SchemaObject()
    var isSingleValueOptional: Bool = false

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let testKeyedDecodingContainer = TestKeyedDecodingContainer<Key>(customStringTypeExamples)
        testKeyedDecodingContainer.delegate = self
        return KeyedDecodingContainer(testKeyedDecodingContainer)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        schemaObject.type = .array
        let testUnkeyedDecodingContainer = TestUnkeyedDecodingContainer(customStringTypeExamples)
        testUnkeyedDecodingContainer.delegate = self
        return testUnkeyedDecodingContainer
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        let testSingleValueDecodingContainer = TestSingleValueDecodingContainer(customStringTypeExamples)
        testSingleValueDecodingContainer.delegate = self
        return testSingleValueDecodingContainer
    }
}
