//
//  Debouncer.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/18/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

/// Fires a callback after the call function has not been called for the specified delay
open class Debouncer {
    var delay: Double
    weak var timer: Timer?

    public init(delay: Double) {
        self.delay = delay
    }

    public func call(_ callback: @escaping () -> ()) {
        timer?.invalidate()
        
        let nextTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            callback()
        }
        
        timer = nextTimer
    }
}

/// Manages a set of debouncers associated with a string
open class IdentifiableDebounceManager {
    private var debouncers: [String: Debouncer] = [:]
    private let delay: Double
    
    public init(_ delay: Double) {
        self.delay = delay
    }
    
    private func debouncer(forID id: String) -> Debouncer {
        if let debouncer = debouncers[id] {
            return debouncer
        }
        
        debouncers[id] = Debouncer(delay: delay)
        
        return debouncers[id]!
    }
    
    private func clearDebouncer(forID id: String) {
        if let index = debouncers.index(forKey: id) {
            debouncers.remove(at: index)
        }
    }
    
    public func submit(id: String, cb: @escaping () -> ()) {
        debouncer(forID: id).call {
            DispatchQueue.main.async {
                self.clearDebouncer(forID: id)
            }
            
            cb()
        }
    }
}

/// Manages a set of managers with the specified categories
open class CategorizedDebounceManager<P: Hashable> {
    private var debouncers: [P: IdentifiableDebounceManager] = [:]
    private let defaultDelay: Double = 1 / 10
    
    public init(_ configuration: [P: Double]) {
        configuration.forEach {
            debouncers[$0.key] = .init($0.value)
        }
    }
    
    private func debouncer(for category: P) -> IdentifiableDebounceManager {
        if let debouncer = debouncers[category] {
            return debouncer
        }
        
        debouncers[category] = .init(defaultDelay)
        
        return debouncers[category]!
    }
    
    public func submit(_ id: String, category: P, cb: @escaping () -> ()) {
        debouncer(for: category).submit(id: id, cb: cb)
    }
}
