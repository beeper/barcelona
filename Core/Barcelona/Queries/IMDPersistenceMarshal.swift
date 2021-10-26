//
//  IMDPersistenceMarshal.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/27/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

private extension Dictionary {
    func merge(into dictionary: inout Dictionary) {
        forEach {
            dictionary[$0.key] = $0.value
        }
    }
}

private extension Collection where Element: Hashable {
    func intersects<SomeCollection: Collection>(collection: SomeCollection) -> Bool where SomeCollection.Element == Element {
        collection.first(where: contains) != nil
    }
}

internal extension OperationBuffer {
    @_transparent
    @usableFromInline
    func performLocked<P>(_ cb: () throws -> P) rethrows -> P {
        lock.lock()
        defer { lock.unlock() }
        return try cb()
    }
}

public class OperationBuffer<Output, Discriminator: Hashable> {
    @usableFromInline
    typealias RawBuffer = Promise<[Output]>
    
    @usableFromInline
    typealias LazyBuffer = Promise<[Discriminator: Output]>
    
    @usableFromInline
    internal var rawBuffers = [[Discriminator]: RawBuffer]()
    private var lazyBuffers = [[Discriminator]: LazyBuffer]()
    
    private var discriminatorKeyPath: KeyPath<Output, Discriminator>
    @usableFromInline
    internal var lock = NSRecursiveLock()
    
    public init(discriminatorKeyPath: KeyPath<Output, Discriminator>) {
        self.discriminatorKeyPath = discriminatorKeyPath
    }
    
    private func lazyBuffer(_ ids: [Discriminator]) -> LazyBuffer? {
        if let lazyBuffer = lazyBuffers[ids] {
            return lazyBuffer
        }
        
        guard let rawBuffer = rawBuffers[ids] else {
            return nil
        }
        
        let lazyBuffer = rawBuffer.dictionary(keyedBy: discriminatorKeyPath)
        
        self.performLocked {
            self.lazyBuffers[ids] = lazyBuffer.observeAlways { _ in
                self.performLocked {
                    self.lazyBuffers[ids] = nil
                }
            }
        }
        
        return lazyBuffer
    }
    
    private func directBuffer(_ ids: [Discriminator]) -> Promise<[Output]>? {
        rawBuffers[ids]
    }
    
    @discardableResult
    @inlinable
    func putBuffers(_ ids: [Discriminator], _ pending: Promise<[Output]>) -> Promise<[Output]> {
        performLocked {
            rawBuffers[ids] = pending.observeAlways { _ in
                self.performLocked {
                    self.rawBuffers[ids] = nil
                }
            }
        }
        
        return pending
    }
    
    @usableFromInline
    func partialBuffer(_ ids: [Discriminator]) -> (Promise<[Output]>, remaining: [Discriminator]?) {
        if let directBuffer = directBuffer(ids) {
            return (directBuffer, nil)
        }
        
        /// aggregate all keys that point to pending results for these ids
        let keys = rawBuffers.keys.filter {
            $0.intersects(collection: ids)
        }
        
        var matched = Set<Discriminator>()
        // computes all ids that have not yet been matched
        var needed: [Discriminator] {
            ids.filter {
                !matched.contains($0)
            }
        }
        var using = [LazyBuffer]()
        
        for key in keys {
            let needed = needed
            let matches = key.filter {
                needed.contains($0)
            }
            
            guard matches.count > 0 else {
                // key did match, but has been superseded by a previous key
                continue
            }
            
            matches.forEach {
                matched.insert($0)
            }
            
            // add the buffer to the chunk we're going to merge
            guard let lazyBuffer = lazyBuffer(key) else {
                continue
            }
            
            using.append(lazyBuffer)
        }
        
        return (
            Promise.all(using)
                // flatten entries
                .flatten()
                // unique the values by key
                .dictionary(keyedBy: \.key, valuedBy: \.value)
                // only use the ones we need
                .filter {
                    ids.contains($0.key)
                }
                .map(\.value),
            remaining: needed.count == 0 ? nil : needed
        )
    }
}

let IMDPersistenceMarshal = OperationBuffer<ChatItem, String>(discriminatorKeyPath: \.id)
