//
// TestUnkeyedDecodingContainer.swift
//
// Created by Andreas in 2020
//

import Foundation

class TestUnkeyedDecodingContainer: UnkeyedDecodingContainer {

    let customStringTypeExamples: [String]

    init(_ customStringTypeExamples: [String]) {
        self.customStringTypeExamples = customStringTypeExamples
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
        if type == UUID.self, let uuid = UUID() as? T {
            schemaObject.type = .string
            delegate?.update(schemaObject: &schemaObject)
            currentIndex += 1
            return uuid
        }
        if type == Date.self, let date = Date() as? T {
            schemaObject.type = .string
            schemaObject.format = .dateTime
            delegate?.update(schemaObject: &schemaObject)
            currentIndex += 1
            return date
        }

        do {
            let decoder = TestDecoder(customStringTypeExamples)
            let value = try T(from: decoder)
            schemaObject = decoder.schemaObject
            delegate?.update(schemaObject: &schemaObject)
            currentIndex += 1
            return value
        } catch {
            for example in customStringTypeExamples {
                do {
                    let value = try JSONDecoder().decode(T.self, from: Data(example.utf8))
                    schemaObject.type = .string
                    delegate?.update(schemaObject: &schemaObject)
                    currentIndex += 1
                    return value
                } catch {}
            }
            throw error
        }
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        assertionFailure("not implemented")
        return KeyedDecodingContainer(TestKeyedDecodingContainer(customStringTypeExamples))
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        assertionFailure("not implemented")
        return self
    }

    func superDecoder() throws -> Decoder {
        assertionFailure("not implemented")
        return TestDecoder(customStringTypeExamples)
    }
}
