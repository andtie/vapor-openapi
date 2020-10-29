//
// OpenAPI.swift
//
// Created by Andreas in 2020
//

import Foundation

/// See https://swagger.io/specification/
public struct OpenAPI: Encodable {

    public var openapi = "3.0.0"
    public var info: Info
    public var servers: [Server]
    public var paths: [String: [Verb: Operation]]
    public var components: Components
    public var security: [[String: [String]]]?

    public struct Info: Encodable {
        public var version = "1.0.0"
        public var title: String
    }

    public struct Server: Encodable {
        public var url: String

        public init(url: String) {
            self.url = url
        }
    }

    public typealias Verb = String

    public enum ParameterLocation: String, Encodable {
        case path, query, header, cookie
    }

    public struct Parameter: Encodable {
        public var name: String
        public var `in`: ParameterLocation
        public var description: String?
        public var required: Bool
        public var schema: SchemaObject
    }

    public typealias ResponseCode = String

    public struct ResponseHeader: Encodable {
        public var description: String?
        public var schema: SchemaObject
    }

    public struct SchemaRef: Encodable {
        public var name: String
        public var isOptional: Bool
        public var isArray: Bool

        init(name: String, isOptional: Bool, isArray: Bool) {
            self.name = name
            self.isOptional = isOptional
            self.isArray = isArray
        }

        enum CodingKeys: String, CodingKey {
            case ref = "$ref"
            case type
            case items
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if isArray {
                try container.encode("array", forKey: .type)
                var nestedContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .items)
                try nestedContainer.encode("#/components/schemas/\(name)", forKey: .ref)
            } else {
                try container.encode("#/components/schemas/\(name)", forKey: .ref)
            }
        }
    }

    public struct ResponseContent: Encodable {
        public var description: String?
        public var schema: SchemaRef
    }

    public typealias ResponseContentFormat = String

    public struct Response: Encodable {
        public var description: String
        public var headers: [String: ResponseHeader]?
        public var content: [ResponseContentFormat: ResponseContent]
    }

    public struct RequestBody: Encodable {
        public var description: String?
        public var content: [String: RequestContent] // "application/json"
        public var required: Bool
    }

    public struct RequestContent: Encodable {
        public var schema: SchemaRef
    }

    public struct Operation: Encodable {
        public var summary: String?
        public var operationId: String
        public var tags: [String]?
        public var parameters: [Parameter]?
        public var requestBody: RequestBody?
        public var responses: [ResponseCode: Response]
    }

    public struct Components: Encodable {
        public var schemas: [String: SchemaObject]
        public var securitySchemes: [String: SecurityScheme]?
    }

    public struct SecurityScheme: Encodable {
        public var type: String
        public var scheme: String?
        public var `in`: ParameterLocation?
        public var name: String?


        public init(type: String, scheme: String?, in: ParameterLocation?, name: String?) {
            self.type = type
            self.scheme = scheme
            self.in = `in`
            self.name = name
        }
    }
}