//
//  Collections.swift
//  Barcelona
//
//  Created by Eric Rabil on 10/27/21.
//

import Foundation

public extension Collection {
    func splitReduce<A, B>(intoLeft left: A, intoRight right: B, callback: (inout A, inout B, Element) throws -> ()) rethrows -> (A, B) {
        try reduce(into: (left, right)) { collector, element in
            try callback(&collector.0, &collector.1, element)
        }
    }
}
