//
// Faker+Content.swift
//
// Created by Andreas in 2020
//

import OpenAPIDecoder

extension Faker {
    public static func content<C: Codable>(configuration: Configuration = .default) throws -> C {
        let decoder = TestDecoder(configuration, delegate: nil)
        _ = try C.init(from: decoder)
        let faker = Faker(schemaObject: decoder.schemaObject, schemas: decoder.schemas.value, configuration: configuration)
        let data = try faker.generateJSON()
        return try configuration.bodyDecoder.decode(C.self, from: .init(data: data), headers: .init())
    }
}
