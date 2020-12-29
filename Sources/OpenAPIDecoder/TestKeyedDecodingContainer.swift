//
// TestKeyedDecodingContainer.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

class TestKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {

    let configuration: CoderConfig

    init(_ configuration: CoderConfig) {
        self.configuration = configuration
    }

    var codingPath: [CodingKey] = []

    var optionalKeys: Set<String> = []
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
        let schemaProperties = SchemaProperties(type: type)
        if let schema = delegate?.schemas.value[schemaProperties.name], let value = delegate?.values[schemaProperties.name] as? T {
            schemaObject = schema
            delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
            return value
        }
        if let inferrable = T.self as? Inferrable.Type ?? Container<T>.self as? Inferrable.Type {
            schemaObject = try inferrable.inferSchema(with: configuration, delegate: delegate)
            delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
            return try inferrable.inferValue(with: configuration, delegate: delegate) as! T
        }
        if !(type.self is PrimitiveJSONType.Type) {
            if delegate?.objectStack.contains(where: { $0 == type }) == true {
                schemaObject = schemaProperties.schemaObject()
                delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
                throw TestDecoder.DecoderError.recursion(schemaProperties)
            }
            delegate?.objectStack.append(type)
        }
        let decoder = TestDecoder(configuration, delegate: delegate)
        let value: T
        do {
            value = try T(from: decoder)
        } catch TestDecoder.DecoderError.recursion(let ref) {
            if let optional = type as? ExpressibleByNilLiteral.Type {
                value = optional.init(nilLiteral: ()) as! T
            } else if let v = [] as? T {
                decoder.schemaObject.items = ref.schemaObject()
                value = v
            } else {
                schemaObject = SchemaProperties(type: type).schemaObject()
                delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: isRequired(key))
                throw TestDecoder.DecoderError.recursion(ref)
            }
        } catch {
            throw error
        }
        schemaObject = decoder.schemaObject
        let required = isRequired(key) && !decoder.isSingleValueOptional
        if schemaObject.type == .object {
            delegate?.schemas.value[schemaProperties.name] = schemaObject
            delegate?.values[schemaProperties.name] = value
        }
        delegate?.update(schemaObject: &schemaObject, for: key.stringValue, required: required)
        return value
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
        return TestDecoder(configuration, delegate: delegate)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        assertionFailure("not implemented")
        return TestDecoder(configuration, delegate: delegate)
    }
}
