//
// SchemaObjectDelegate.swift
//
// Created by Andreas in 2020
//

import Foundation

protocol SchemaObjectDelegate: AnyObject {
    var schemaObject: SchemaObject { get set }
}

extension SchemaObjectDelegate {
    func update(schemaObject: inout SchemaObject) {
        if self.schemaObject.type == .array {
            self.schemaObject.items = schemaObject
        } else {
            self.schemaObject = schemaObject
        }
        schemaObject = SchemaObject()
    }

    func update(schemaObject: inout SchemaObject, for key: String, required: Bool) {
        var properties = self.schemaObject.properties ?? [:]
        properties[key] = schemaObject
        self.schemaObject.properties = properties
        if required, self.schemaObject.required?.contains(key) != true {
            var required = self.schemaObject.required ?? []
            required.append(key)
            self.schemaObject.required = required
        }
        schemaObject = SchemaObject()
    }
}
