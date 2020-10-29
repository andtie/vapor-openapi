//
// EventLoopFuture+Extensions.swift
//
// Created by Andreas in 2020
//

import Vapor

protocol RouteResult {
    static var resultType: Any.Type { get }
}

extension EventLoopFuture: RouteResult {
    static var resultType: Any.Type {
        Value.self
    }
}

protocol HasContentType {
    static var contentType: HTTPMediaType { get }
}

extension EventLoopFuture: HasContentType where Value: Content {
    static var contentType: HTTPMediaType {
        Value.defaultContentType
    }
}
