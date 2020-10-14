//
// SchemaObject.swift
//
// Created by Andreas in 2020
//

import Foundation

/// See also: https://swagger.io/specification/
final class SchemaObject: Encodable {
    enum ObjectType: String, Encodable {
        case object, array, integer, number, boolean, string
    }

    enum Format: String, Encodable {
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

    var type: ObjectType
    var format: Format?
    var required: [String]?
    var items: SchemaObject?
    var properties: [String: SchemaObject]?

    init() {
        type = .object
    }

    init(type: ObjectType) {
        self.type = type
    }
}
