//
//  main.swift
//  docgen
//
//  Created by Eric Rabil on 8/16/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftCLI
import BarcelonaDocs

private extension String {
    var convertingLiteralToTypeScriptEquivalent: String {
        switch self {
        case "String":
            return "string"
        case "Bool":
            return "boolean"
        case "Int8":
            return "number"
        case "UInt8":
            return "number"
        case "Int32":
            return "number"
        case "UInt32":
            return "number"
        case "Int64":
            return "number"
        case "UInt64":
            return "number"
        case "Float":
            return "number"
        case "Double":
            return "number"
        default:
            return self
        }
    }
}

extension ParsedType {
    private var _undefToTypescript: String {
        toTypescript(convertingOptionalToUndefinedUnion: true)
    }
    
    private func toTypescript(convertingOptionalToUndefinedUnion: Bool) -> String {
        switch self {
        case .optional(let type):
            if convertingOptionalToUndefinedUnion {
                return "\(type._undefToTypescript) | undefined"
            } else {
                return type._undefToTypescript
            }
        case .array(let type):
            switch type {
            case .literal(let text):
                return "\(text.convertingLiteralToTypeScriptEquivalent)[]"
            default:
                return "Array<\(type._undefToTypescript)>"
            }
        case .dictionary(let key, let value):
            return "Record<\(key._undefToTypescript), \(value._undefToTypescript)"
        case .literal(let text):
            return text.convertingLiteralToTypeScriptEquivalent
        case .unknown:
            return "never"
        }
    }
    
    var typescript: String {
        toTypescript(convertingOptionalToUndefinedUnion: false)
    }
}

extension SwiftProperty {
    var typescript: String {
        """
        \(name)\(optionalToken): \(type.typescript);
        """
    }
    
    private var optionalToken: String {
        switch type {
        case .optional:
            return "?"
        default:
            return ""
        }
    }
}

extension SwiftEnumCase {
    var impliedType: String {
        parent.
    }
    
    var typescript: String {
        "\(name) = \(rawValue)"
    }
}

extension SwiftNode {
    var instanceProperties: [SwiftProperty] {
        properties.filter {
            !$0.isStatic
        }
    }
    
    var exportTypeToken: String {
        switch type {
        case .enum:
            return "enum"
        default:
            return "interface"
        }
    }
    
    var typescript: String {
        switch type {
        case .enum:
            return """
            export enum \(name) {
            }
            """
        default:
            return """
            export interface \(name) {
            \(instanceProperties.map(\.typescript).map { "\t" + $0 }.joined(separator: "\n"))
            }
            """
        }
    }
}

class DocGenCommand: Command {
    let name = "gen"
    
    @Param(completion: .filename)
    var folder: String
    
    var folderURL: URL {
        URL(fileURLWithPath: folder, isDirectory: true)
    }
    
    func execute() throws {
        let nodes = try folderURL.parseDirectoryToSwiftNodes()
        
        print(nodes.filter {
            $0.attributes.contains(.exposed)
        }.map(\.typescript).joined(separator: "\n\n"))
    }
}

CLI(singleCommand: DocGenCommand()).goAndExit()
