//
//  SwiftNode+SS.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

public extension SwiftNode {
    static func eat(parser: SourceFileSyntax) -> [SwiftNode] {
        parser.statements
            .map(\.item)
            .compactMap(self.eat(syntax:))
    }
    
    static func eat(syntax: Syntax) -> SwiftNode? {
        guard let parent = MemberProvidingCoerce(from: syntax) else {
            return nil
        }
        
        var node = SwiftNode(name: parent.identifier.text)
        node.type = parent.type
        node.attributes = SwiftAttributes.parse(syntax: syntax)
        eat(decls: parent.members.members.map(\.decl), into: &node)
        
        return node
    }
}

fileprivate extension SwiftNode {
    static func eat(decls: [DeclSyntax], into node: inout SwiftNode) {
        for decl in decls {
            if let caseDecl = decl.as(EnumCaseDeclSyntax.self), let caseNode = SwiftEnumCase(parent: node, decl: caseDecl) {
                node.cases.append(caseNode)
            } else if let varDecl = decl.as(VariableDeclSyntax.self) {
                node.properties.append(contentsOf: SwiftProperty.properties(fromDecl: varDecl))
            } else if let funcDecl = decl.as(FunctionDeclSyntax.self) {
                node.functions.append(SwiftFunction(decl: funcDecl))
            } else if decl.is(ClassDeclSyntax.self) || decl.is(EnumDeclSyntax.self) || decl.is(ProtocolDeclSyntax.self) || decl.is(StructDeclSyntax.self), let node = eat(syntax: Syntax(decl)) {
                node.nodes.append(node)
            }
        }
    }
}
