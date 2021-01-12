//
// RouteFaker.swift
//
// Created by Andreas in 2020
//

import Vapor
import OpenAPIDecoder
import OpenAPI
import OpenAPIFaker

public class RouteFaker: Command {

    public struct Signature: CommandSignature {
        public init() {}
        @Argument(name: "path") var path: String
    }

    public var help: String {
        "generates fake data for all configured routes"
    }

    private(set) var configuration: CoderConfig

    public init(configuration: CoderConfig = .init(coder: ContentConfiguration.global)) {
        self.configuration = configuration
    }

    public enum RouteFakerError: Error {
        case unexpectedType(String)
    }

    public func add<T: Codable>(example: T, for schema: SchemaObject) {
        configuration.schemaExamples.append(SchemaExample(example: example, for: schema))
    }

    public func add(exampleData: Data, for schema: SchemaObject) {
        configuration.schemaExamples.append(SchemaExample(data: exampleData, for: schema))
    }

    public func run(using context: CommandContext, signature: Signature) throws {
        var schemas: [String: SchemaObject] = [:]

        for route in context.application.routes.all {
            guard let data = try fakedResponse(for: route, schemas: &schemas) else {
                continue
            }
            let path = route.path.map { "\($0)" }
                .joined(separator: "_")
                .replacingOccurrences(of: ":", with: "$")
                .appending(".json")
            let name = "/" + route.method.string.lowercased() + "_" + path
            let url = URL(fileURLWithPath: signature.path + name)
            try data.write(to: url)
        }

        context.console.print("fake-data written to \(signature.path)")
    }

    func fakedResponse(for route: Route, schemas: inout [String: SchemaObject]) throws -> Data? {
        guard let type = route.responseType as? RouteResult.Type,
              let codable = type.resultType as? Codable.Type
        else {
            throw RouteFakerError.unexpectedType("\(route.responseType)")
        }

        guard !(codable is HTTPResponseStatus.Type) else { return nil }

        let decoder = TestDecoder(configuration, delegate: nil)
        _ = try decoder.properties(for: codable, schemas: &schemas)

        return try Faker(schemaObject: decoder.schemaObject, schemas: schemas, configuration: configuration, rng: .init())
            .generateJSON()
    }
}

protocol RouteResult {
    static var resultType: Any.Type { get }
}

extension EventLoopFuture: RouteResult {
    static var resultType: Any.Type {
        Value.self
    }
}
