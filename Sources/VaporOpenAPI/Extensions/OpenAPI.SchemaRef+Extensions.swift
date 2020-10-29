//
// OpenAPI.SchemaRef+Extensions.swift
//
// Created by Andreas in 2020
//

import Foundation

extension OpenAPI.SchemaRef {
    init(for type: Any.Type, object: SchemaObject, schemas: inout [String: SchemaObject]) {
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
             schemas[name] = object.items
         } else {
             schemas[name] = object
         }

        self.name = name
        self.isOptional = isOptional
        self.isArray = isArray
     }
}
