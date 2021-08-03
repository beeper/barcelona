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
    /// The duration in which calls will be throttled
    var delay: Double
    
    /// The timer being tracked by the debouncer
    weak var timer: Timer?

    public init(delay: Double) {
        self.delay = delay
    }
    
    /// Fires a callback function if and only if there are no subsequent calls during the debounce period
    /// - Parameter callback: callback function to call
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
    /// Debouncers for the given identifiers
    private var debouncers: [String: Debouncer] = [:]
    
    /// The duration in which calls for a given identifier will be throttled
    private let delay: Double
    
    public init(_ delay: Double) {
        self.delay = delay
    }
    
    /// Returns or constructs a debouncer for the given id
    /// - Parameter id: id to resolve
    /// - Returns: debouncer object
    private func debouncer(forID id: String) -> Debouncer {
        if let debouncer = debouncers[id] {
            return debouncer
        }
        
        debouncers[id] = Debouncer(delay: delay)
        
        return debouncers[id]!
    }
    
    /// Drops a debouncer from storage
    /// - Parameter id: identifier of the debouncer to clear
    private func clearDebouncer(forID id: String) {
        if let index = debouncers.index(forKey: id) {
            debouncers.remove(at: index)
        }
    }
    
    /// Submits a task to an identifiable debouncer
    /// - Parameters:
    ///   - id: identifier of the debouncer to call
    ///   - cb: task to execute if conditions are met
    public func submit(id: String, cb: @escaping () -> ()) {
        debouncer(forID: id).call {
            RunLoop.main.schedule {
                self.clearDebouncer(forID: id)
            }
            
            cb()
        }
    }
}

/// Manages a set of managers with the specified categories
open class CategorizedDebounceManager<P: Hashable> {
    /// Ledger of category to debounce manager
    private var debouncers: [P: IdentifiableDebounceManager] = [:]
    
    /// Default delay to use for debounce managers
    private let defaultDelay: Double = 1 / 10
    
    /// Constructs a categorized debounce manager
    /// - Parameter configuration: ledger of debounce categories to delays
    public init(_ configuration: [P: Double]) {
        configuration.forEach {
            debouncers[$0.key] = .init($0.value)
        }
    }
    
    /// Returns or constructs a debouncer for the given category
    /// - Parameter category: category of the debouncer to resolve
    /// - Returns: a debounce manager
    private func debouncer(for category: P) -> IdentifiableDebounceManager {
        if let debouncer = debouncers[category] {
            return debouncer
        }
        
        debouncers[category] = .init(defaultDelay)
        
        return debouncers[category]!
    }
    
    /// Submits a task to a debouncer on a given category
    /// - Parameters:
    ///   - id: identifier of the debouncer
    ///   - category: category of the debouncer
    ///   - cb: task to execute if conditions are met
    public func submit(_ id: String, category: P, cb: @escaping () -> ()) {
        debouncer(for: category).submit(id: id, cb: cb)
    }
}
