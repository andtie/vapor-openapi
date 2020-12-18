//
// SchemaObject.swift
//
// Created by Andreas in 2020
//

import Foundation

/// See also: https://swagger.io/specification/#schema-object
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
        case email
        case uuid
    }

    public var type: ObjectType?
    public var format: Format?
    public var required: [String]?
    public var items: SchemaObject? // for arrays
    public var properties: [String: SchemaObject]?
    public var description: String?
    public var additionalProperties: SchemaObject? // for dictionaries
    public var `enum`: [AnyPrimitiveJSONType]?
    public var ref: String?

    enum CodingKeys: String, CodingKey {
        case type
        case format
        case required
        case items
        case properties
        case description
        case additionalProperties
        case `enum` = "enum"
        case ref = "$ref"
    }

    public init() {
        type = .object
    }

    public init(type: ObjectType, format: Format? = nil, description: String? = nil) {
        self.type = type
        self.format = format
        self.description = description
    }

    public init(ref: String) {
        self.ref = ref
    }
}
