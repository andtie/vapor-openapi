//
// ParameterExporter.swift
//
// Created by Andreas in 2020
//

import Vapor

struct ParameterExporter {

    let configuration: Configuration

    func parameters(for route: Route, of app: Application, schemas: inout [String: SchemaObject]) throws -> (OpenAPI.RequestBody?, [OpenAPI.Parameter]) {

        let bodyDecoder = TestContentDecoder(configuration, delegate: nil)
        ContentConfiguration.global.use(decoder: bodyDecoder, for: .json)
        defer { ContentConfiguration.global.use(decoder: configuration.bodyDecoder, for: .json) }

        let queryDecoder = TestURLQueryDecoder(configuration, delegate: nil)
        ContentConfiguration.global.use(urlDecoder: queryDecoder)
        defer { ContentConfiguration.global.use(urlDecoder: configuration.urlLDecoder) }

        for example in configuration.schemaExamples {
            var parameters = Parameters()
            for case let .parameter(parameter) in route.path {
                guard let data = example.data(configuration, .path),
                      let string = String(data: data, encoding: .utf8)
                else { continue }
                parameters.set(parameter, to: string)
            }
            let request = Request(application: app, on: app.eventLoopGroup.next())
            request.parameters = parameters
            request.headers.contentType = .json
            struct EmptyContent: Content {}
            try? request.content.encode(EmptyContent())
            configuration.preProcessor(request)
            _ = try? route.responder.respond(to: request).wait()
        }

        let body: OpenAPI.RequestBody? = bodyDecoder.result.map { decoder, decodable in
            let properties = SchemaProperties(type: decodable)
            schemas[properties.name] = properties.isArray ? decoder.schemaObject.items : decoder.schemaObject
            return OpenAPI.RequestBody(
                description: nil,
                content: [
                    "application/json": .init(schema: properties.schemaObject())
                ],
                required: !properties.isOptional
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
}
