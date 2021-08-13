//
//  JSContext+Completion.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/12/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//
//  Shamelessly ported from https://github.com/nodejs/node/blob/master/lib/repl.js
//

import Foundation
import JavaScriptCore

// MARK: - Public API
public extension JSContext {
    func completion(forLine line: String) -> [String] {
        let (match, base) = line.match(#"(?:[a-zA-Z_$](?:\w|\$)*\??\.)*[a-zA-Z_$](?:\w|\$)*\??\.?$"#)
        
        if line.count > 0, match.count == 0 {
            return []
        }
        
        return completionGroups(forExpression: match).map { entry in
            base + entry
        }
    }
}

// MARK: - Completion Implementations
private extension JSContext {
    /// Used when the input is empty, suggesting globally-visible variables (both built-in and part of the API)
    func topLevelCompletions() -> [[String]] {
        var completionGroups = [[String]]()
        
        var proto = globalObject.prototype
        while proto != nil {
            completionGroups.append(proto!.propertyNames)
            proto = proto!.prototype
        }
        
        completionGroups.append(globalObject.propertyNames)
        
        return completionGroups
    }
    
    /// Takes a partial expression and suggests the next node in it
    func completionGroups(forExpression expression: String) -> [String] {
        var expression = expression
        var refinement: String? = nil
        
        if expression.hasSuffix(".") {
            expression = String(expression.prefix(expression.count - 1))
        } else if expression.count > 0 {
            var bits = expression.split(separator: ".")
            refinement = String(bits.popLast()!)
            expression = bits.joined(separator: ".")
        }
        
        if expression.count == 0 {
            return topLevelCompletions().uniqueCompletions(withFilter: refinement)
        }
        
        var chaining = "."
        if expression.hasSuffix("?") {
            expression = String(expression.prefix(expression.count - 1))
            chaining = "?."
        }
        
        let evalExpr = "try { \(expression) } catch {}"
        
        let obj = evaluateScript(atomically: evalExpr)
        
        var proto: JSValue? = nil
        var memberGroups: [[String]] = []
        
        if (obj.isObject && !obj.isNull) || obj.isFunction {
            memberGroups.append(obj.propertyNames)
            proto = obj.prototype
        } else {
            proto = obj["constructor"]?["prototype"]
        }
        
        var sentinel = 5
        while proto != nil, sentinel != 0 {
            memberGroups.append(proto!.propertyNames)
            proto = proto!.prototype
            sentinel -= 1
        }
        
        var completionGroups = [[String]]()
        
        if memberGroups.count > 0 {
            expression += chaining
            memberGroups.forEach { group in
                completionGroups.append(group.map { member in "\(expression)\(member)" })
            }
        }
        
        if let refinement = refinement {
            return completionGroups.uniqueCompletions(withFilter: expression + refinement)
        } else {
            return completionGroups.uniqueCompletions(withFilter: nil)
        }
    }
}

// MARK: - Completion Helpers
private extension Collection where Element == [String] {
    func uniqueCompletions(withFilter filter: String?) -> [String] {
        var completions = [String]()
        var uniqueSet = Set<String>()
        
        for group in self {
            var group = group
            
            if let filter = filter {
                group = group.filter { entry in
                    entry.starts(with: filter)
                }
            }
            
            group.sorted(by: >).forEach { entry in
                if !uniqueSet.contains(entry) {
                    completions.insert(entry, at: 0)
                    uniqueSet.insert(entry)
                }
            }
        }
        
        return completions
    }
}

private extension String {
    func match(_ expression: String) -> (String, String) {
        guard let range = range(of: expression, options: .regularExpression) else {
            return ("", expression)
        }
        
        return (String(self[range]), String(self[..<range.lowerBound]))
    }
}
