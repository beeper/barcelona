//
//  ExpiringCollection.swift
//  BarcelonaFoundation
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import OSLog

public class ExpiringCollection<Element: Hashable>: Collection {
    public private(set) var inner = Set<Element>()
    
    public typealias Index = Set<Element>.Index
    
    public let threshold: TimeInterval = 60
    public var runLoop: RunLoop = .current
    
    private var expirationTimers = [Element: Timer]()
    
    public var startIndex: Set<Element>.Index { inner.startIndex }
    public var endIndex: Set<Element>.Index { inner.endIndex }
    
    public init() {
        
    }
    
    public func insert(_ item: Element) {
        inner.insert(item)
        expirationTimers[item]?.invalidate()
        
        runLoop.schedule {
            self.expirationTimers[item] = Timer.scheduledTimer(withTimeInterval: self.threshold, repeats: false) { timer in
                self.expirationTimers[item] = nil
                self.inner.remove(item)
            }
        }
    }
    
    public func remove(_ item: Element) {
        inner.remove(item)
        expirationTimers[item]?.invalidate()
    }
    
    public subscript(index: Set<Element>.Index) -> Element {
        inner[index]
    }
    
    public func index(after i: Set<Element>.Index) -> Set<Element>.Index {
        inner.index(after: i)
    }
}
