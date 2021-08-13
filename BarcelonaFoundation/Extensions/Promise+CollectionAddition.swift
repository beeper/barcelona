//
//  Promise+CollectionAddition.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 8/2/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Pwomise

public extension Promise where Output: Collection {
    static func + (left: Promise, right: Promise) -> Promise<[Output.Element]> {
        Promise.all([left, right]).flatten()
    }
    
    static func + (left: Promise, right: [Output.Element]) -> Promise<[Output.Element]> {
        left.then {
            $0 + right
        }
    }
    
    static func + (left: [Output.Element], right: Promise) -> Promise<[Output.Element]> {
        right.then {
            left + $0
        }
    }
}

public extension Promise {
    static func catching(_ block: @escaping (@escaping Resolve, @escaping Reject) throws -> ()) -> Promise {
        Promise { resolve, reject in
            do {
                try block(resolve, reject)
            } catch {
                reject(error)
            }
        }
    }
}
