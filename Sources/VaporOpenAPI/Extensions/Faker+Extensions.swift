//
// Faker+Extensions.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPIFaker
import Vapor

extension Faker {
    public static func content<C: Codable>() throws -> C {
        try content(configuration: .init(coder: ContentConfiguration.current))
    }
}
