//
//  Collection.swift
//  Extensions
//
//  Created by June Welker on 7/25/23.
//

import Foundation

public extension Collection {
    // Stolen from Swexy
    @inlinable
    func collectedDictionary<Key: Hashable, Value>(
        keyedBy key: KeyPath<Element, Optional<Key>>,
        valuedBy value: KeyPath<Element, Optional<Value>>
    ) -> [Key: [Value]] {
        reduce(into: [Key: [Value]]()) { dict, entry in
            guard let key = entry[keyPath: key], let value = entry[keyPath: value] else { return }
            if dict[key] == nil { dict[key] = [value] }
            else { dict[key]!.append(value) }
        }
    }

    @inlinable
    func collectedDictionary<Key: Hashable, Value>(
        keyedBy key: KeyPath<Element, Optional<Key>>,
        valuedBy value: KeyPath<Element, Value>
    )-> [Key: [Value]] {
        reduce(into: [Key: [Value]]()) { dict, entry in
            guard let key = entry[keyPath: key] else { return }
            if dict[key] == nil { dict[key] = [] }
            dict[key]!.append(entry[keyPath: value])
        }
    }
    
    /// Creates a dictionary whose key is represented by the first keypath and whose value is an array of element[value] where element[key] matches
    @inlinable
    func collectedDictionary<Key: Hashable, Value>(keyedBy key: KeyPath<Element, Key>, valuedBy value: KeyPath<Element, Value>) -> [Key: [Value]] {
        reduce(into: [Key: [Value]]()) { dict, entry in
            let key = entry[keyPath: key]
            if dict[key] == nil { dict[key] = [] }
            dict[key]!.append(entry[keyPath: value])
        }
    }

    @inlinable
    func collectedDictionary<Key: Hashable>(keyedBy key: KeyPath<Element, Optional<Key>>) -> [Key: [Element]] {
        collectedDictionary(keyedBy: key, valuedBy: \Element.self)
    }

    @inlinable
    func collectedDictionary<Key: Hashable>(keyedBy key: KeyPath<Element, Key>) -> [Key: [Element]] {
        collectedDictionary(keyedBy: key, valuedBy: \Element.self)
    }
    
    /// Creates a dictionary whose key is represented by the keypath and whose value is that of this collection
    @inlinable
    func dictionary<Key: Hashable>(keyedBy key: KeyPath<Element, Key>) -> [Key: Element] {
        dictionary(keyedBy: key, valuedBy: \Element.self)
    }
    
    /// Creates a dictionary whose key is represented by the keypath and whose value is all of the elements who have a non-nill value for said keypath
    @inlinable
    func dictionary<Key: Hashable>(keyedBy key: KeyPath<Element, Optional<Key>>) -> [Key: Element] {
        dictionary(keyedBy: key, valuedBy: \Element.self)
    }
    
    /// Creates a dictionary whose key is represented by the first keypath and whose value is represented by the second keypath
    @inlinable
    func dictionary<Key: Hashable, Value>(keyedBy key: KeyPath<Element, Key>, valuedBy value: KeyPath<Element, Value>) -> [Key: Value] {
        reduce(into: [Key: Value]()) { dict, entry in
            dict[entry[keyPath: key]] = entry[keyPath: value]
        }
    }
    
    /// Creates a dictionary whose key is represented by the first keypath and whose value is represented by the second keypath, for every element with a non-nill value for the first keypath
    @inlinable
    func dictionary<Key: Hashable, Value>(keyedBy key: KeyPath<Element, Optional<Key>>, valuedBy value: KeyPath<Element, Value>) -> [Key: Value] {
        reduce(into: [Key: Value]()) { dict, entry in
            guard let key = entry[keyPath: key] else { return }
            dict[key] = entry[keyPath: value]
        }
    }
    
    @inlinable
    // used as such: arr.sorted(usingKey: \.date, by: >)
    func sorted<Value: Comparable>(usingKey key: KeyPath<Element, Value>, by areInIncreasingOrder: (Value, Value) throws -> Bool) rethrows -> [Element] {
        try self.sorted(by: { a, b in
            try areInIncreasingOrder(a[keyPath: key], b[keyPath: key])
        })
    }
}
