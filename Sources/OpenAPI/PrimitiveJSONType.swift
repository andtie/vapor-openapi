//
// PrimitiveJSONType.swift
//
// Created by Andreas in 2020
//

import Foundation

public protocol PrimitiveJSONType: Codable {}

extension Int: PrimitiveJSONType {}
extension UInt: PrimitiveJSONType {}
extension Bool: PrimitiveJSONType {}
extension Int8: PrimitiveJSONType {}
extension Int16: PrimitiveJSONType {}
extension Int32: PrimitiveJSONType {}
extension Int64: PrimitiveJSONType {}
extension UInt8: PrimitiveJSONType {}
extension UInt16: PrimitiveJSONType {}
extension UInt32: PrimitiveJSONType {}
extension UInt64: PrimitiveJSONType {}
extension Float: PrimitiveJSONType {}
extension Double: PrimitiveJSONType {}
extension String: PrimitiveJSONType {}

extension Array: PrimitiveJSONType where Element: PrimitiveJSONType {}
extension Optional: PrimitiveJSONType where Wrapped: PrimitiveJSONType {}

public struct AnyPrimitiveJSONType: Encodable {

    public let value: Any
    let encoder: (Encoder) throws -> Void

    public func encode(to encoder: Encoder) throws {
        try self.encoder(encoder)
    }

    public init<T: PrimitiveJSONType>(value: T) {
        self.value = value
        encoder = value.encode(to:)
    }
}
