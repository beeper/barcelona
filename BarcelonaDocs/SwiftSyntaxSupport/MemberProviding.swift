//
//  MemberProviding.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

internal protocol MemberProviding {
    var members: MemberDeclBlockSyntax { get set }
    var type: SwiftNode.SwiftNodeType { get }
    var identifier: TokenSyntax { get set }
}

func MemberProvidingCoerce(from syntax: Syntax) -> MemberProviding? {
    syntax.as(EnumDeclSyntax.self) ?? syntax.as(ClassDeclSyntax.self) ?? syntax.as(ProtocolDeclSyntax.self) ?? syntax.as(StructDeclSyntax.self)
}

extension EnumDeclSyntax: MemberProviding {
    var type: SwiftNode.SwiftNodeType {
        .enum
    }
}

extension ClassDeclSyntax: MemberProviding {
    var type: SwiftNode.SwiftNodeType {
        .class
    }
}

extension ProtocolDeclSyntax: MemberProviding {
    var type: SwiftNode.SwiftNodeType {
        .protocol
    }
}

extension StructDeclSyntax: MemberProviding {
    var type: SwiftNode.SwiftNodeType {
        .struct
    }
}
