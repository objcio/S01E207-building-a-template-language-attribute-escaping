//
//  File.swift
//  
//
//  Created by Florian Kugler on 13-05-2020.
//

import Foundation

public enum TemplateValue: Hashable {
    case string(String)
    case rawHTML(String)
}

public struct EvaluationContext {
    public init(values: [String : TemplateValue] = [:]) {
        self.values = values
    }
    
    public var values: [String: TemplateValue]
}

public struct EvaluationError: Error, Hashable {
    public var range: Range<String.Index>
    public var reason: Reason
    
    public enum Reason: Hashable {
        case variableMissing(String)
        case expectedString
    }
}

extension EvaluationContext {
    public func evaluate(_ expr: AnnotatedExpression) throws -> TemplateValue {
        switch expr.expression {
        case .variable(name: let name):
            guard let value = values[name] else {
                throw EvaluationError(range: expr.range, reason: .variableMissing(name))
            }
            return value
        case .tag(let name, let attributes, let body):
            let bodyValues = try body.map { try self.evaluate($0) }
            let bodyString = bodyValues.map { value in
                switch value {
                case let .string(str): return str.escaped
                case let .rawHTML(html): return html
                }
            }.joined()
            let attText = try attributes.isEmpty ? "" : " " + attributes.map { (key, value) in
                guard case let .string(valueText) = try evaluate(value) else {
                    throw EvaluationError(range: value.range, reason: .expectedString)
                }
                return "\(key)=\"\(valueText.attributeEscaped)\""
            }.joined(separator: " ")
            
            let result = "<\(name)\(attText)>\(bodyString)</\(name)>"
            return .rawHTML(result)
        }
    }
}

extension String {
    // todo verify that this is secure
    var escaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
    
    var attributeEscaped: String {
        replacingOccurrences(of: "\"", with: "&quot;")
    }
}
