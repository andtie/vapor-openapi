//
// OpenAPI.swift
//
// Created by Andreas in 2020
//

import Foundation

/// See https://swagger.io/specification/
struct OpenAPI: Encodable {

    var openapi = "3.0.0"
    var info: Info
    var servers: [Server]
    var paths: [String: [Verb: Operation]]
    var components: Components

    struct Info: Encodable {
        var version = "1.0.0"
        var title: String
    }

    struct Server: Encodable {
        var url: String
    }

    typealias Verb = String

    enum ParameterLocation: String, Encodable {
        case path, query, header, cookie
    }

    struct Parameter: Encodable {
        var name: String
        var `in`: ParameterLocation
        var description: String?
        var required: Bool
        var schema: SchemaObject
    }

    typealias ResponseCode = String

    struct ResponseHeader: Encodable {
        var description: String?
        var schema: SchemaObject
    }

    struct SchemaRef: Encodable {
        var name: String

        enum CodingKeys: String, CodingKey {
            case ref = "$ref"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("#/components/schemas/\(name)", forKey: .ref)
        }
    }

    struct ResponseContent: Encodable {
        var description: String?
        var schema: SchemaRef
    }

    typealias ResponseContentFormat = String

    struct Response: Encodable {
        var description: String
        var headers: [String: ResponseHeader]?
        var content: [ResponseContentFormat: ResponseContent]
    }

    struct Operation: Encodable {
        var summary: String?
        var operationId: String
        var tags: [String]?
        var parameters: [Parameter]?
        var responses: [ResponseCode: Response]
    }

    struct Components: Encodable {
        var schemas: [String: SchemaObject]
    }
}
