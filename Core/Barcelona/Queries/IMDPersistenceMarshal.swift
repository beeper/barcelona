//
//  IMDPersistenceMarshal.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/27/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Combine

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
    typealias RawBuffer = Future<[Output], Never>
    
    @usableFromInline
    typealias LazyBuffer = Future<[Discriminator: Output], Never>
    
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

        let lazyBuffer = rawBuffer.map {
            $0.dictionary(keyedBy: self.discriminatorKeyPath)
        }.toFuture()
        
        self.performLocked {
            self.lazyBuffers[ids] = Future<[Discriminator: Output], Never> { resolve in
                Task {
                    let values = await lazyBuffer.value
                    self.performLocked {
                        _ = self.lazyBuffers.removeValue(forKey: ids)
                    }
                    resolve(.success(values))
                }
            }
        }
        
        return lazyBuffer
    }
    
    private func directBuffer(_ ids: [Discriminator]) -> Future<[Output], Never>? {
        rawBuffers[ids]
    }
    
    @inlinable
    func putBuffers(_ ids: [Discriminator], _ pending: Future<[Output], Never>) {
        performLocked {
            rawBuffers[ids] = Future<[Output], Never> { resolve in
                Task {
                    let values = await pending.value
                    _ = self.performLocked {
                        self.rawBuffers.removeValue(forKey: ids)
                    }
                    resolve(.success(values))
                }
            }
        }
    }
    
    @usableFromInline
    func partialBuffer(_ ids: [Discriminator]) -> (Future<[Output], Never>, remaining: [Discriminator]?) {
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
            Future<[Output], Never> { resolve in
                // We need this to access the captured var `using` in concurrent code
                let getValues: () async -> [Discriminator: Output] = {
                    var values = [Discriminator: Output]()
                    // Get all the values from the buffers that we're trying to use
                    for fut in using {
                        let newVals = await fut.value
                        for val in newVals {
                            values[val.key] = val.value
                        }
                    }

                    return values
                }

                Task {
                    let resolved = await getValues()
                        .dictionary(keyedBy: \.key, valuedBy: \.value)
                        .filter {
                            ids.contains($0.key)
                        }
                        .map(\.value)

                    resolve(.success(resolved))
                }
            },
            remaining: needed.count == 0 ? nil : needed
        )
    }
}

let IMDPersistenceMarshal = OperationBuffer<ChatItem, String>(discriminatorKeyPath: \.id)
