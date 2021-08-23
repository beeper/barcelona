//
//  SwiftEnumCase+SS.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

public extension SwiftEnumCase {
    convenience init?(parent: SwiftNode, decl: EnumCaseDeclSyntax) {
        guard decl.elements.count == 1, let element = decl.elements.first else {
            return nil
        }
        
        self.init(
            parent: parent,
            name: element.identifier.text,
            rawValue: element.rawValue?.value.description,
            associatedValues: element.associatedValue?.parameterList.compactMap(\.type).map(\.description),
            attributes: SwiftAttributes.parse(syntax: Syntax(decl))
        )
    }
}
