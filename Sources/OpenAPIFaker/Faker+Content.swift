//
// Faker+Content.swift
//
// Created by Andreas in 2020
//

import OpenAPIDecoder

extension Faker {
    public static func content<C: Codable>(configuration: CoderConfig) throws -> C {
        let decoder = TestDecoder(configuration, delegate: nil)
        _ = try C(from: decoder)
        let faker = Faker(schemaObject: decoder.schemaObject, schemas: decoder.schemas.value, configuration: configuration)
        let data = try faker.generateJSON()
        return try configuration.coder.decodeAsBody(data: data)
    }
}
