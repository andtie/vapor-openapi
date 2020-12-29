//
// Route+Extensions.swift
//
// Created by Andreas in 2020
//

import OpenAPI
import Vapor

extension Route {

    var verb: String {
        method.rawValue.lowercased()
    }

    var apiPath: String {
        "/" + path.map { component in
            switch component {
            case .parameter(let parameter):
                return "{\(parameter)}"
            default:
                return "\(component)"
            }
        }
        .joined(separator: "/")
    }

    var apiParamaters: [OpenAPI.Parameter] {
        path.compactMap { component -> OpenAPI.Parameter? in
            guard case let .parameter(parameter) = component else { return nil }
            return OpenAPI.Parameter(
                name: parameter,
                in: .path,
                description: nil,
                required: true,
                schema: SchemaObject(type: .string)
            )
        }
    }
}
