//
// ExportOpenAPI.swift
//
// Created by Andreas in 2020
//

import Vapor

public struct ExportOpenAPI: Command {

    public init() {}

    public struct Signature: CommandSignature {
        public init() {}
        @Argument(name: "path") var path: String
    }

    public var help: String {
        "exports all configured routes"
    }

    enum ExportError: Error {
        case error(String?)
    }

    func response(for route: Route, schemas: inout [String: SchemaObject]) throws -> OpenAPI.Response {
        let contentType = (route.responseType as? HasContentType.Type)?.contentType ?? .json
        guard contentType == .json else {
            throw ExportError.error("Unexpected Content Type \(contentType)")
        }
        guard let type = route.responseType as? RouteResult.Type,
              let codable = type.resultType as? Codable.Type
        else {
            throw ExportError.error("Unexpected Result Type \(route.responseType)")
        }

        // let contenDecoder = try ContentConfiguration.global.requireDecoder(for: contentType)
        // let strategy = (contenDecoder as? JSONDecoder)?.dateDecodingStrategy ?? .iso8601

        let name = String(reflecting: type.resultType)
            .components(separatedBy: ".")
            .dropFirst()
            .joined(separator: ".")

        let decoder = TestDecoder()
        _ = try codable.init(from: decoder)
        schemas[name] = decoder.schemaObject

        return .init(
            description: name,
            headers: nil,
            content: [
                "application/json": .init(description: nil, schema: .init(name: name))
            ]
        )
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

            var pathDict = paths[path] ?? [:]
            let verb = route.method.rawValue.lowercased()
            let operationId = route.path.map { "\($0)" } + [verb]

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

            let operation = OpenAPI.Operation(
                summary: route.userInfo["description"] as? String,
                operationId: operationId.joined(separator: "-"),
                tags: nil,
                parameters: pathParameters,
                responses: [
                    "default": try response(for: route, schemas: &schemas)
                ]
            )

            pathDict[verb] = operation
            paths[path] = pathDict
        }

        let openAPI = OpenAPI(
            info: .init(title: "One App Backend"),
            servers: [.init(url: "http://127.0.0.1:8080")],
            paths: paths,
            components: .init(schemas: schemas)
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(openAPI)
        let url = URL(fileURLWithPath: signature.path)
        try data.write(to: url)

        context.console.print("spec written to \(signature.path)")
    }
}

private protocol RouteResult {
    static var resultType: Any.Type { get }
}

extension EventLoopFuture: RouteResult {
    static var resultType: Any.Type {
        Value.self
    }
}

private protocol HasContentType {
    static var contentType: HTTPMediaType { get }
}

extension EventLoopFuture: HasContentType where Value: Content {
    static var contentType: HTTPMediaType {
        Value.defaultContentType
    }
}
