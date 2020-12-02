//
// TestKeyedDecodingContainer.swift
//
// Created by Andreas in 2020
//

import Foundation

class TestKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol, SchemaObjectDelegate {

    let configuration: Configuration

    init(_ configuration: Configuration) {
        self.configuration = configuration
    }

    var codingPath: [CodingKey] = []

    var optionalKeys: Set<String> = []
    var isSingleValueOptional: Bool = false
    var schemaObject = SchemaObject()
    weak var delegate: SchemaObjectDelegate?

    private func isRequired(_ key: Key) -> Bool {
        !optionalKeys.contains(key.stringValue)
    }

    var allKeys: [Key] = []

    func contains(_ key: Key) -> Bool {
        optionalKeys.insert(key.stringValue)
        return true
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        optionalKeys.insert(key.stringValue)
        return false
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        schemaObject.type = .boolean
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return true
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        schemaObject.type = .string
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return ""
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        schemaObject.type = .number
        schemaObject.format = .double
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        schemaObject.type = .number
        schemaObject.format = .float
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        schemaObject.type = .integer
        schemaObject.format = .int32
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        schemaObject.type = .integer
        schemaObject.format = .int64
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
        return 0
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T: Decodable {
        for example in configuration.schemaExamples {
            if let value = try? example.value(for: type, configuration: configuration, location: .body) {
                schemaObject = example.schema
                delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
                return value
            }
        }
        if let dict = type as? AnyStringDict.Type {
            let decoder = try dict.valueDecoder(for: configuration)
            schemaObject.additionalProperties = decoder.schemaObject
            delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
            return [:] as! T
        }
        let decoder = TestDecoder(configuration)
        defer {
            schemaObject = decoder.schemaObject
            let required = isRequired(key) && !decoder.isSingleValueOptional
            delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: required)
        }
        return try T(from: decoder)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        assertionFailure("not implemented")
        return KeyedDecodingContainer(TestKeyedDecodingContainer<NestedKey>(configuration))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        assertionFailure("not implemented")
        return TestUnkeyedDecodingContainer(configuration)
    }

    func superDecoder() throws -> Decoder {
        assertionFailure("not implemented")
        return TestDecoder(configuration)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        assertionFailure("not implemented")
        return TestDecoder(configuration)
    }
}

protocol AnyStringDict {
    static func valueDecoder(for configuration: Configuration) throws -> TestDecoder
}

extension Dictionary: AnyStringDict where Key == String, Value: Decodable {
    static func valueDecoder(for configuration: Configuration) throws -> TestDecoder {
        let decoder = TestDecoder(configuration)
        _ = try Value(from: decoder)
        return decoder
    }
}
