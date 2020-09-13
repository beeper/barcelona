//
//  Identifiable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public protocol Identifiable {
    associatedtype ID: Codable, Hashable
    
    var id: ID { get }
}

extension Array where Element: Identifiable {
    var ledger: [Element.ID: Element] {
        reduce(into: [Element.ID: Element]()) { ledger, element in
            ledger[element.id] = element
        }
    }
}
