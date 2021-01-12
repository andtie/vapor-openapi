//
// Faker+Vapor.swift
//
// Created by Andreas in 2020
//

import Foundation
import OpenAPIFaker
import Vapor

#if canImport(VaporOpenAPI)
    import VaporOpenAPI

    extension Faker {
        public static func content<C: Codable>() throws -> C {
            try content(configuration: .init(coder: ContentConfiguration.current))
        }
    }
#else
    extension Faker {
        public static func content<C: Codable>() throws -> C {
            try content(configuration: .init(coder: ContentConfiguration.global))
        }
    }
#endif
