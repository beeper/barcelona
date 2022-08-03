//
//  Tracer.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/3/22.
//

import Foundation
import Swog

public struct Tracer {
    public let log: Logger
    public let debugEnabled: () -> Bool
    
    public init(_ log: Logger, _ debugEnabled: @escaping @autoclosure () -> Bool) {
        self.log = log
        self.debugEnabled = debugEnabled
    }
}
 
public extension Tracer {
    @_transparent func time<P>(callback: () -> P) -> (P, TimeInterval) {
        guard debugEnabled() else {
            return (callback(), 0)
        }
        let start = Date()
        let result = callback()
        let stop = Date()
        let diff = start.distance(to: stop)
        return (result, diff)
    }
    
    @_transparent func callAsFunction<P>(_ name: @autoclosure () -> String, callback: () -> P) -> P {
        guard debugEnabled() else {
            return callback()
        }
        let start = Date()
        defer {
            let stop = Date()
            let diff = start.distance(to: stop)
            let name = name()
            log.debug("\(name, privacy: .public) took \(diff, privacy: .public) seconds")
        }
        return callback()
    }
}
