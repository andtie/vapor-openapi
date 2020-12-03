//
// Faker+Content.swift
//
// Created by Andreas in 2020
//

import Vapor

extension Faker {
    public static func content<C: Content>(configuration: Configuration = .default) throws -> C {
        let decoder = TestDecoder(configuration)
        _ = try C.init(from: decoder)
        let faker = Faker(schemaObject: decoder.schemaObject, configuration: configuration)
        let data = try faker.generateJSON()
        return try configuration.bodyDecoder.decode(C.self, from: .init(data: data), headers: .init())
    }
}
