//
// ExportOpenAPI.swift
//
// Created by Andreas in 2020
//

import Vapor

public struct ExportOpenAPI: Command {

    let preProcessor: (Request) -> Void
    let postProcessor: (inout OpenAPI) -> Void

    public init(preProcessor: @escaping (Request) -> Void = { _ in }, postProcessor: @escaping (inout OpenAPI) -> Void = { _ in }) {
        self.preProcessor = preProcessor
        self.postProcessor = postProcessor
    }

    public struct Signature: CommandSignature {
        public init() {}
        @Argument(name: "path") var path: String
    }

    public var help: String {
        "exports all configured routes"
    }

    public mutating func add<T: Codable>(example: T, for schema: SchemaObject) {
        if let schemaExample = SchemaExample(example: example, for: schema) {
            schemaExamples.append(schemaExample)
        }
    }

    public mutating func add(exampleData: Data, for schema: SchemaObject) {
        schemaExamples.append(SchemaExample(data: exampleData, for: schema))
    }

    enum ExportError: Error {
        case generic
        case text(String)
    }

    var schemaExamples: [SchemaExample] = [
        SchemaExample(example: UUID(), for: SchemaObject(type: .string)),
        SchemaExample(example: Date(), for: SchemaObject(type: .string, format: .dateTime)),
    ].compactMap { $0 }

    static var previousBodyDecoder: ContentDecoder?
    static var previousURLDecoder: URLQueryDecoder?

    func parameters(for route: Route, of app: Application, schemas: inout [String: SchemaObject]) throws -> (OpenAPI.RequestBody?, [OpenAPI.Parameter]) {

        let bodyDecoder = TestContentDecoder(schemaExamples)
        Self.previousBodyDecoder = try ContentConfiguration.global.requireDecoder(for: .json)
        ContentConfiguration.global.use(decoder: bodyDecoder, for: .json)
        defer { Self.previousBodyDecoder.map { ContentConfiguration.global.use(decoder: $0, for: .json) } }

        let queryDecoder = TestURLQueryDecoder(schemaExamples)
        Self.previousURLDecoder = try ContentConfiguration.global.requireURLDecoder()
        ContentConfiguration.global.use(urlDecoder: queryDecoder)
        defer { Self.previousURLDecoder.map { ContentConfiguration.global.use(urlDecoder: $0) } }

        // path values might be expected in different formats, so we try some common ones
        for example in schemaExamples {
            var parameters = Parameters()
            for case let .parameter(parameter) in route.path {
                if var string = String(data: example.data, encoding: .utf8) {
                    string = string.trimmingCharacters(in: .init(charactersIn: "\""))
                    parameters.set(parameter, to: string)
                }
            }
            let request = Request(application: app, on: app.eventLoopGroup.next())
            request.parameters = parameters
            request.headers.contentType = .json
            struct EmptyContent: Content {}
            try? request.content.encode(EmptyContent())
            preProcessor(request)
            _ = try? route.responder.respond(to: request).wait()
        }

        let body: OpenAPI.RequestBody? = bodyDecoder.result.map { decoder, decodable in
            let ref = self.ref(for: decodable, object: decoder.schemaObject, schemas: &schemas)
            return OpenAPI.RequestBody(
                description: nil,
                content: [
                    "application/json": .init(schema: ref)
                ],
                required: !ref.isOptional
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

        let decoder = TestDecoder(schemaExamples)
        _ = try codable.init(from: decoder)
        let ref = self.ref(for: codable, object: decoder.schemaObject, schemas: &schemas)

        return .init(
            description: ref.name,
            headers: nil,
            content: [
                "application/json": .init(description: nil, schema: ref)
            ]
        )
    }

    func ref(for type: Any.Type, object: SchemaObject, schemas: inout [String: SchemaObject]) -> OpenAPI.SchemaRef {
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

        return .init(name: name, isOptional: isOptional, isArray: isArray)
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

            let (body, queries) = try parameters(for: route, of: context.application, schemas: &schemas)

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
