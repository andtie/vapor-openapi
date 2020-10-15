//
// SchemaObject.swift
//
// Created by Andreas in 2020
//

import Foundation

/// See also: https://swagger.io/specification/
public final class SchemaObject: Encodable {
    public enum ObjectType: String, Encodable {
        case object, array, integer, number, boolean, string
    }

    public enum Format: String, Encodable {
        case int32
        case int64
        case float
        case double
        case byte // base64 encoded characters
        case binary // any sequence of octets
        case date // As defined by full-date - RFC3339
        case dateTime = "date-time" // As defined by date-time - RFC3339
        case password // A hint to UIs to obscure input.
    }

    public var type: ObjectType
    public var format: Format?
    public var required: [String]?
    public var items: SchemaObject?
    public var properties: [String: SchemaObject]?

    public init() {
        type = .object
    }

    public init(type: ObjectType) {
        self.type = type
    }
}
