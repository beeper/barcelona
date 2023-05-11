//
//  Sequence.swift
//  Extensions
//
//  Created by June Welker on 5/10/23.
//

import Foundation

public extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            values.append(try await transform(element))
        }
        return values
    }
}

public struct ExtensionsTesting { }
