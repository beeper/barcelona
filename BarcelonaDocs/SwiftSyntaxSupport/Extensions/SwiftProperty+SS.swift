//
//  SwiftProperty+SS.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

private extension VariableDeclSyntax {
    func hasModifier(named name: String) -> Bool {
        modifiers?.contains(where: {
            $0.name.text == name
        }) ?? false
    }
}

public extension SwiftProperty {
    static func properties(fromDecl decl: VariableDeclSyntax) -> [SwiftProperty] {
        decl.bindings.compactMap { binding in
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier, let type = binding.typeAnnotation?.type else {
                return nil
            }
            
            if let accessor = binding.accessor {
                if let block = accessor.as(AccessorBlockSyntax.self), block.accessors.contains(where: {
                    $0.accessorKind.text == "get"
                }) {
                    return nil
                } else if accessor.is(CodeBlockSyntax.self) {
                    return nil
                }
            }
            
            return SwiftProperty(
                name: identifier.text,
                type: ParsedType(rawValue: type),
                isStatic: decl.hasModifier(named: "static"),
                attributes: SwiftAttributes.parse(syntax: Syntax(decl))
            )
        }
    }
}
