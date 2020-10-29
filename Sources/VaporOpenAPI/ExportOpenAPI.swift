//
// ExportOpenAPI.swift
//
// Created by Andreas in 2020
//

import Vapor

public struct ExportOpenAPI: Command {

    var configuration: Configuration

    public init(preProcessor: @escaping (Request) -> Void = { _ in }, postProcessor: @escaping (inout OpenAPI) -> Void = { _ in }) {
        configuration = Configuration.default
        configuration.preProcessor = preProcessor
        configuration.postProcessor = postProcessor
    }

    public struct Signature: CommandSignature {
        public init() {}
        @Argument(name: "path") var path: String
    }

    public var help: String {
        "exports all configured routes"
    }

    public mutating func add<T: Codable>(example: T, for schema: SchemaObject) {
        configuration.schemaExamples.append(SchemaExample(example: example, for: schema))
    }

    public mutating func add(exampleData: Data, for schema: SchemaObject) {
        configuration.schemaExamples.append(SchemaExample(data: exampleData, for: schema))
    }

    public enum ExportError: Error {
        case generic
        case text(String)
    }

    public func run(using context: CommandContext, signature: Signature) throws {

        var schemas: [String: SchemaObject] = [:]
        var paths: [String: [OpenAPI.Verb: OpenAPI.Operation]] = [:]

        for route in context.application.routes.all {
            let path = "/" + route.path
                .map { component in
                    switch component {
                    case .parameter(let parameter):
                        return "{\(parameter)}"
                    default:
                        return "\(component)"
                    }
                }
                .joined(separator: "/")

            let pathParameters = route.path.compactMap { component -> OpenAPI.Parameter? in
                guard case let .parameter(parameter) = component else { return nil }
                return OpenAPI.Parameter(
                    name: parameter,
                    in: .path,
                    description: nil,
                    required: true,
                    schema: SchemaObject(type: .string)
                )
            }

            var pathDict = paths[path] ?? [:]
            let verb = route.method.rawValue.lowercased()
            let operationId = route.path.map { "\($0)" } + [verb]

            let exporter = ParameterExporter(configuration: configuration)
            let (body, queries) = try exporter.parameters(for: route, of: context.application, schemas: &schemas)

            let operation = OpenAPI.Operation(
                summary: route.userInfo["description"] as? String,
                operationId: operationId.joined(separator: "-"),
                tags: nil,
                parameters: pathParameters + queries,
                requestBody: body,
                responses: [
                    "default": try response(for: route, schemas: &schemas)
                ]
            )

            pathDict[verb] = operation
            paths[path] = pathDict
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

    // MARK: - Private

    private func response(for route: Route, schemas: inout [String: SchemaObject]) throws -> OpenAPI.Response {
        let contentType = (route.responseType as? HasContentType.Type)?.contentType ?? .json
        guard contentType == .json else {
            throw ExportError.text("Unexpected Content Type \(contentType)")
        }
        guard let type = route.responseType as? RouteResult.Type,
              let codable = type.resultType as? Codable.Type
        else {
            throw ExportError.text("Unexpected Result Type \(route.responseType)")
        }

        let decoder = TestDecoder(configuration)
        _ = try codable.init(from: decoder)
        let ref = OpenAPI.SchemaRef(for: codable, object: decoder.schemaObject, schemas: &schemas)

        return .init(
            description: ref.name,
            headers: nil,
            content: [
                "application/json": .init(description: nil, schema: ref)
            ]
        )
    }
}
