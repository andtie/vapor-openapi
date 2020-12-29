//
// ExportCommand.swift
//
// Created by Andreas in 2020
//

import Vapor
import OpenAPIDecoder
import OpenAPI

public struct ExportCommand: Command {

    public var configuration: Configuration = .default

    public init() {}

    public struct Signature: CommandSignature {
        public init() {}
        @Argument(name: "path") var path: String
    }

    public var help: String {
        "exports all configured routes"
    }

    public mutating func add<T: Codable>(example: T, for schema: SchemaObject) {
        configuration.coderConfig.schemaExamples.append(SchemaExample(example: example, for: schema))
    }

    public mutating func add(exampleData: Data, for schema: SchemaObject) {
        configuration.coderConfig.schemaExamples.append(SchemaExample(data: exampleData, for: schema))
    }

    public func run(using context: CommandContext, signature: Signature) throws {

        var schemas: [String: SchemaObject] = [:]
        var paths: [String: [OpenAPI.Verb: OpenAPI.Operation]] = [:]

        let exporter = OperationExporter(configuration: configuration, app: context.application)

        for route in context.application.routes.all {
            var pathDict = paths[route.apiPath] ?? [:]
            pathDict[route.verb] = try exporter.operation(for: route, schemas: &schemas)
            paths[route.apiPath] = pathDict
        }

        var openAPI = OpenAPI(
            info: .init(title: "Open API"),
            servers: [.init(url: "http://127.0.0.1:8080")],
            paths: paths,
            components: .init(schemas: schemas, securitySchemes: nil),
            security: nil
        )

        configuration.postProcessor(&openAPI)

        let encoder = JSONEncoder()
        #if os(Linux)
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        #else
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        #endif
        let data = try encoder.encode(openAPI)
        let url = URL(fileURLWithPath: signature.path)
        try data.write(to: url)

        context.console.print("spec written to \(signature.path)")
    }
}
