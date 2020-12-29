//
// SchemaProperties.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPI

public struct SchemaProperties {
    public let name: String
    public let isOptional: Bool
    public let isArray: Bool

    public init(type: Any.Type) {
        var name = String(reflecting: type)
            .components(separatedBy: ".")
            .dropFirst()
            .joined(separator: ".")

        let isOptional = name.hasPrefix("Optional<")
        if isOptional {
            name = String(name.dropFirst("Optional<".count).dropLast())
                .components(separatedBy: ".")
                .dropFirst()
                .joined(separator: ".")
        }

        let isArray = name.hasPrefix("Array<")
        if isArray {
            name = String(name.dropFirst("Array<".count).dropLast())
                .components(separatedBy: ".")
                .dropFirst()
                .joined(separator: ".")
        }

        self.name = name
        self.isOptional = isOptional
        self.isArray = isArray
    }

    public func schemaObject() -> SchemaObject {
        if isArray {
            let object = SchemaObject(type: .array)
            object.items = SchemaObject(ref: "#/components/schemas/\(name)")
            return object
        } else {
            return SchemaObject(ref: "#/components/schemas/\(name)")
        }
    }
}
