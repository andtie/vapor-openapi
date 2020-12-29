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

    public init(
        info: Info,
        servers: [Server],
        paths: [String: [Verb: Operation]],
        components: Components,
        security: [[String: [String]]]?,
        openapi: String = "3.0.0"
    ) {
        self.info = info
        self.servers = servers
        self.paths = paths
        self.components = components
        self.security = security
        self.openapi = openapi
    }

    public struct Info: Encodable {
        public var version = "1.0.0"
        public var title: String

        public init(title: String, version: String = "1.0.0") {
            self.title = title
            self.version = version
        }
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

        public init(name: String, in: ParameterLocation, description: String?, required: Bool, schema: SchemaObject) {
            self.name = name
            self.in = `in`
            self.description = description
            self.required = required
            self.schema = schema
        }
    }

    public typealias ResponseCode = String

    public struct ResponseHeader: Encodable {
        public var description: String?
        public var schema: SchemaObject

        public init(description: String?, schema: SchemaObject) {
            self.description = description
            self.schema = schema
        }
    }

    public struct ResponseContent: Encodable {
        public var description: String?
        public var schema: SchemaObject

        public init(description: String?, schema: SchemaObject) {
            self.description = description
            self.schema = schema
        }
    }

    public typealias ResponseContentFormat = String

    public struct Response: Encodable {
        public var description: String
        public var headers: [String: ResponseHeader]?
        public var content: [ResponseContentFormat: ResponseContent]

        public init(description: String, headers: [String: ResponseHeader]?, content: [ResponseContentFormat: ResponseContent]) {
            self.description = description
            self.headers = headers
            self.content = content
        }
    }

    public struct RequestBody: Encodable {
        public var description: String?
        public var content: [String: RequestContent] // "application/json"
        public var required: Bool

        public init(description: String?, content: [String: RequestContent], required: Bool) {
            self.description = description
            self.content = content
            self.required = required
        }
    }

    public struct RequestContent: Encodable {
        public var schema: SchemaObject
        public init(schema: SchemaObject) {
            self.schema = schema
        }
    }

    public struct Operation: Encodable {
        public var summary: String?
        public var description: String?
        public var operationId: String
        public var tags: [String]?
        public var parameters: [Parameter]?
        public var requestBody: RequestBody?
        public var responses: [ResponseCode: Response]

        public init(
            summary: String?,
            description: String?,
            operationId: String,
            tags: [String]?,
            parameters: [Parameter]?,
            requestBody: RequestBody?,
            responses: [ResponseCode: Response]
        ) {
            self.summary = summary
            self.description = description
            self.operationId = operationId
            self.tags = tags
            self.parameters = parameters
            self.requestBody = requestBody
            self.responses = responses
        }
    }

    public struct Components: Encodable {
        public var schemas: [String: SchemaObject]
        public var securitySchemes: [String: SecurityScheme]?

        public init(schemas: [String: SchemaObject], securitySchemes: [String: SecurityScheme]?) {
            self.schemas = schemas
            self.securitySchemes = securitySchemes
        }
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
