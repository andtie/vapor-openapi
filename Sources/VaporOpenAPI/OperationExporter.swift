//
// OperationExporter.swift
//
// Created by Andreas in 2020
//

import OpenAPI
import OpenAPIDecoder
import Vapor

struct OperationExporter {

    let configuration: Configuration
    let app: Application

    func operation(for route: Route, schemas: inout [String: SchemaObject]) throws -> OpenAPI.Operation {
        let exporter = ParameterExporter(configuration: configuration)
        let (body, queries) = try exporter.parameters(for: route, of: app, schemas: &schemas)
        let operationId = route.path.map { "\($0)" } + [route.verb]
        return OpenAPI.Operation(
            summary: nil,
            description: route.userInfo["description"] as? String,
            operationId: operationId.joined(separator: "-"),
            tags: nil,
            parameters: route.apiParamaters + queries,
            requestBody: body,
            responses: [
                "default": try response(for: route, schemas: &schemas)
            ]
        )
    }

    func response(for route: Route, schemas: inout [String: SchemaObject]) throws -> OpenAPI.Response {
        let contentType = (route.responseType as? HasContentType.Type)?.contentType ?? .json
        guard contentType == .json else {
            throw ExportError.text("Unexpected Content Type \(contentType)")
        }
        guard let type = route.responseType as? RouteResult.Type,
              let codable = type.resultType as? Codable.Type
        else {
            throw ExportError.text("Unexpected Result Type \(route.responseType)")
        }

        let decoder = TestDecoder(configuration.coderConfig, delegate: nil)
        let properties = try decoder.properties(for: codable, schemas: &schemas)

        return .init(
            description: properties.name,
            headers: nil,
            content: [
                "application/json": .init(description: nil, schema: properties.schemaObject())
            ]
        )
    }
}
