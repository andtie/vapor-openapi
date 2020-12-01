//
// Faker.swift
//
// Created by Andreas in 2020
//

import Foundation

struct Faker {
    let schemaObject: SchemaObject
    let configuration: Configuration

    static var rng = IteratingRandomNumberGenerator()
    static var arrayCount = 10

    enum FakerError: Error {
        case propertiesEmpty
        case itemsEmpty
    }

    func generateJSON() throws -> Data {
        let value = try generateJSON(hint: nil)
        let dict = value as? [String: Any] ?? ["value": value]
        return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
    }

    func generateJSON(hint: String?) throws -> Any {
        switch schemaObject.type {
        case .object:
            guard let properties = schemaObject.properties else {
                throw FakerError.propertiesEmpty
            }
            let mapped = try properties.map { key, value in
                try (key, Faker(schemaObject: value, configuration: configuration)
                        .generateJSON(hint: key))
            }
            return Dictionary(mapped, uniquingKeysWith: { x, y in x })
        case .array:
            guard let itemType = schemaObject.items else {
                throw FakerError.itemsEmpty
            }
            return try (0..<Faker.arrayCount).map { _ in
                try Faker(schemaObject: itemType, configuration: configuration)
                    .generateJSON(hint: hint)
            }
        case .integer:
            switch schemaObject.format {
            case .int32:
                return Int32.random(using: &Self.rng)
            case .int64:
                return Int64.random(using: &Self.rng)
            default:
                return Int.random(using: &Self.rng)
            }
        case .number:
            switch schemaObject.format {
            case .float:
                return Float.random(in: 0...100, using: &Self.rng)
            default:
                return Double.random(in: 0...100, using: &Self.rng)
            }
        case .boolean:
            return Bool.random(using: &Self.rng)
        case .string:
            switch schemaObject.format {
            case .byte:
                return "iVBORw0KGgoAAAANSUhEUgAAAOEAAADhCAMAAAAJbSJIAAAASFBMVEX/AAD/fX3/jIz/m5v/q6v/uLj/trb/qan/ior/gYH/2dn/dHT/eHj//Pz/8/P/5OT/z8//yMj/srL/kZH/lZX/oKD/rq7/pKT5lJt8AAABl0lEQVR4nO3dS24CMRAG4TYzw2MgDwiQ+980WWQRZROE1GqVXZ8v8NfSkiXHy+vb+n4+L8tymed5N/342Py2b087bP51nR5wmx9wX/7arnGJvh1jrp6QrA1Q+Fk9IVmLqXpCMgv5LOSzkM9CPgv5Rii8Vk9I1mJTPSGZhXwW8lnIZyGfhXwW8lnIZyGfhXwW8lnIZyGfhXwW8lnIN0LhvnpCsvZ9+mYhn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvK1OFRPSDbCi6H+X31ZSGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8IxT2/8+MhXQW8lnIZyGfhXwW8lnIZyGfhXwW8lnIZyGfhXwW8lnIZyGfhXwjFN6qJyRrsauekKzFXD0hmYV8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8FvJZyGchn4V8Le7VE5K12FZPSNZiqZ6QzEI+C/ks5LOQz0I+C/ks5BuhsPcb8CnWY+vZafkCI00HxRaYb6EAAAAASUVORK5CYII="
            case .date, .dateTime:
                let date = Date(timeIntervalSinceReferenceDate: Double.random(in: 0...1e9, using: &Self.rng))
                let data = configuration.encode(example: date)!
                return String(data: data, encoding: .utf8)!
                    .trimmingCharacters(in: .init(charactersIn: "\""))
            case .email:
                return "test@example.com"
            case .uuid:
                return String(format: "00000000-0000-0000-0000-%012d", Self.rng.nextValue())
            default:
                let hints = hint?.componentsSeparatedByCamelCase() ?? []
                if hints.contains("id") || hints.contains("identifier") || hints.contains("identification") {
                    return String(Self.rng.nextValue())
                }
                if hints.contains("name") {
                    let names = ["Frank", "Walter", "Maria", "Heribert", "Gustav", "Joe", "Danielle", "Lisa"]
                    let length = UInt.random(in: 1...3, using: &Self.rng)
                    return (1...length)
                        .map { _ in names.randomElement(using: &Self.rng) ?? names[0] }
                        .joined(separator: " ")
                }
                if hints.contains("phone") {
                    return String(format: "+49 123 %07d", UInt.random(in: 0...9999999, using: &Self.rng))
                }
                if hints.contains("number") {
                    return String(UInt.random(using: &Self.rng))
                }
                return "test-\(hints.joined(separator: "-"))"
            }
        }
    }
}

extension String {
    func componentsSeparatedByCamelCase() -> [String] {
        camelCaseToSnakeCase().components(separatedBy: "_")
    }

    fileprivate func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"
        return processCamelCaseRegex(pattern: acronymPattern)?
            .processCamelCaseRegex(pattern: normalPattern)?.lowercased() ?? lowercased()
    }

    fileprivate func processCamelCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}

public class IteratingRandomNumberGenerator: RandomNumberGenerator {
    var value: UInt64 = 0

    public func nextValue() -> UInt64 {
        defer { value += 1 }
        return value
    }

    public func next() -> UInt64 {
        UInt64(abs(nextValue().hashValue))
    }
}
