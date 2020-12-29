//
// TestUnkeyedDecodingContainer.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

class TestUnkeyedDecodingContainer: UnkeyedDecodingContainer {

    let configuration: CoderConfig

    init(_ configuration: CoderConfig) {
        self.configuration = configuration
    }

    var schemaObject = SchemaObject()
    weak var delegate: SchemaObjectDelegate?

    var codingPath: [CodingKey] = []

    var count: Int? = 1

    var isAtEnd: Bool { count == currentIndex }

    var currentIndex: Int = 0

    func decodeNil() throws -> Bool {
        currentIndex += 1
        return false
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        schemaObject.type = .boolean
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return true
    }

    func decode(_ type: String.Type) throws -> String {
        schemaObject.type = .string
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return ""
    }

    func decode(_ type: Double.Type) throws -> Double {
        schemaObject.type = .number
        schemaObject.format = .double
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: Float.Type) throws -> Float {
        schemaObject.type = .number
        schemaObject.format = .float
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: Int.Type) throws -> Int {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        schemaObject.type = .integer
        schemaObject.format = .int32
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        schemaObject.type = .integer
        schemaObject.format = .int64
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        schemaObject.type = .integer
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return 0
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        if !(type.self is PrimitiveJSONType.Type) {
            for example in configuration.schemaExamples {
                if let value = try? example.value(for: type, configuration: configuration, location: .body) {
                    schemaObject = example.schema
                    delegate?.update(schemaObject: &schemaObject)
                    currentIndex += 1
                    return value
                }
            }
            let schemaProperties = SchemaProperties(type: type)
            if let schema = delegate?.schemas.value[schemaProperties.name], let value = delegate?.values[schemaProperties.name] as? T {
                schemaObject = schema
                delegate?.update(schemaObject: &schemaObject)
                currentIndex += 1
                return value
            }
            if let inferrable = T.self as? Inferrable.Type ?? Container<T>.self as? Inferrable.Type {
                schemaObject = try inferrable.inferSchema(with: configuration, delegate: delegate)
                delegate?.update(schemaObject: &schemaObject)
                currentIndex += 1
                return try inferrable.inferValue(with: configuration, delegate: delegate) as! T
            }
            if delegate?.objectStack.contains(where: { $0 == type }) == true {
                schemaObject = schemaProperties.schemaObject()
                delegate?.update(schemaObject: &schemaObject)
                currentIndex += 1
                throw TestDecoder.DecoderError.recursion(schemaProperties)
            }
            delegate?.objectStack.append(type)
        }
        let decoder = TestDecoder(configuration, delegate: delegate)
        let value: T
        do {
            value = try T(from: decoder)
        } catch TestDecoder.DecoderError.recursion(let props) {
            if schemaObject.type == .object {
                delegate?.schemas.value[props.name] = decoder.schemaObject
            }
            throw TestDecoder.DecoderError.recursion(props)
        } catch {
            throw error
        }
        schemaObject = decoder.schemaObject
        if schemaObject.type == .object {
            let name = SchemaProperties(type: type).name
            delegate?.schemas.value[name] = schemaObject
            delegate?.values[name] = value
        }
        delegate?.update(schemaObject: &schemaObject)
        currentIndex += 1
        return value
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        assertionFailure("not implemented")
        return KeyedDecodingContainer(TestKeyedDecodingContainer(configuration))
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        assertionFailure("not implemented")
        return self
    }

    func superDecoder() throws -> Decoder {
        assertionFailure("not implemented")
        return TestDecoder(configuration, delegate: delegate)
    }
}
