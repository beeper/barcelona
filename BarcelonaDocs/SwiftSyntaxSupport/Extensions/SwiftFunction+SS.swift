//
//  SwiftFunction+SS.swift
//  BarcelonaDocs
//
//  Created by Eric Rabil on 8/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftSyntax

public extension SwiftFunction {
    convenience init(decl: FunctionDeclSyntax) {
        self.init(attributes: SwiftAttributes.parse(syntax: Syntax(decl)))
    }
}
