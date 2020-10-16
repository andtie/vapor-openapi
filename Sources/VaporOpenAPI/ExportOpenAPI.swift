//
// ExportOpenAPI.swift
//
// Created by Andreas in 2020
//

import Vapor

public struct ExportOpenAPI<A: Authenticatable>: Command {

    let auth: (() -> A)?
    let postProcessor: (inout OpenAPI) -> Void

    public init(auth: @autoclosure @escaping () -> A, postProcessor: @escaping (inout OpenAPI) -> Void = { _ in }) {
        self.auth = auth
        self.postProcessor = postProcessor
    }

    public init(postProcessor: @escaping (inout OpenAPI) -> Void = { _ in }) {
        self.auth = nil
        self.postProcessor = postProcessor
    }

    public struct Signature: CommandSignature {
        public init() {}
        @Argument(name: "path") var path: String
    }

    public var help: String {
        "exports all configured routes"
    }

    enum ExportError: Error {
        case generic
        case text(String)
    }

    func parameters(for route: Route, of app: Application, schemas: inout [String: SchemaObject]) -> (OpenAPI.RequestBody?, [OpenAPI.Parameter]) {

        let bodyDecoder = TestContentDecoder()
        ContentConfiguration.global.use(decoder: bodyDecoder, for: .json)
        let queryDecoder = TestURLQueryDecoder()
        ContentConfiguration.global.use(urlDecoder: queryDecoder)

        // path values might be expected in different formats, so we try some common ones
        for pathValue in ["string", "1", UUID().uuidString, "2000-01-01T00:00:00.000Z"] {
            var parameters = Parameters()
            for case let .parameter(parameter) in route.path {
                parameters.set(parameter, to: pathValue)
            }
            let request = Request(application: app, on: app.eventLoopGroup.next())
            request.parameters = parameters
            request.headers.contentType = .json
            if let auth = self.auth?() {
                request.auth.login(auth)
            }
            try? request.content.encode(EmptyContent())

            _ = try? route.responder.respond(to: request).wait()
        }

        let body: OpenAPI.RequestBody? = bodyDecoder.result.map { decoder, decodable in
            var name = extractName(from: decodable)
            let isOptional = name.hasPrefix("Optional<")
            if isOptional {
                name = String(name.dropFirst("Optional<".count).dropLast())
                    .components(separatedBy: ".")
                    .dropFirst()
                    .joined(separator: ".")
            }
            schemas[name] = decoder.schemaObject
            return OpenAPI.RequestBody(
                description: nil,
                content: [
                    "application/json": .init(schema: .init(name: name))
                ],
                required: !isOptional
            )
        }

        let queries: [OpenAPI.Parameter] = queryDecoder.decoders
            .flatMap { decoder in
                decoder.schemaObject.properties?.map { key, schema in
                    OpenAPI.Parameter(
                        name: key,
                        in: .query,
                        description: nil,
                        required: decoder.schemaObject.required?.contains(key) == true,
                        schema: schema
                    )
                } ?? []
            }
            .reduce(into: []) { result, parameter in
                if !result.contains(where: { $0.name == parameter.name }) {
                    result.append(parameter)
                }
            }

        return (body, queries)
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

        let decoder = TestDecoder()
        _ = try codable.init(from: decoder)
        let name = extractName(from: codable)
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

        // let contenDecoder = try ContentConfiguration.global.requireDecoder(for: contentType)
        // let dateDecodingStrategy = (contenDecoder as? JSONDecoder)?.dateDecodingStrategy ?? .iso8601

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

            let (body, queries) = parameters(for: route, of: context.application, schemas: &schemas)

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

        postProcessor(&openAPI)

        let encoder = JSONEncoder()
        if #available(macOS 10.15, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(openAPI)
        let url = URL(fileURLWithPath: signature.path)
        try data.write(to: url)

        context.console.print("spec written to \(signature.path)")
    }
}

private func extractName(from type: Any.Type) -> String {
    String(reflecting: type)
        .components(separatedBy: ".")
        .dropFirst()
        .joined(separator: ".")
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

struct EmptyContent: Content {}

class TestContentDecoder: ContentDecoder {

    var result: (TestDecoder, Any.Type)?

    func decode<D>(_ decodable: D.Type, from body: ByteBuffer, headers: HTTPHeaders) throws -> D where D: Decodable {
        result = (TestDecoder(), decodable)
        return try decodable.init(from: result!.0)
    }
}

class TestURLQueryDecoder: URLQueryDecoder {
    var decoders: [TestDecoder] = []

    func decode<D>(_ decodable: D.Type, from url: URI) throws -> D where D: Decodable {
        let decoder = TestDecoder()
        decoders.append(decoder)
        return try decodable.init(from: decoder)
    }
}
