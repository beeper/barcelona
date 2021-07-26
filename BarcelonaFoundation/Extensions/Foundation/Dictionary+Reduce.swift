//
//  Dictionary+Reduce.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 7/25/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

public extension Collection {
    func dictionary<Key: Hashable>(keyedBy key: KeyPath<Element, Key>) -> [Key: Element] {
        reduce(into: [Key: Element]()) { dict, entry in
            dict[entry[keyPath: key]] = entry
        }
    }
    
    func dictionary<Key: Hashable, Value>(keyedBy key: KeyPath<Element, Key>, valuedBy value: KeyPath<Element, Value>) -> [Key: Value] {
        reduce(into: [Key: Value]()) { dict, entry in
            dict[entry[keyPath: key]] = entry[keyPath: value]
        }
    }
}
