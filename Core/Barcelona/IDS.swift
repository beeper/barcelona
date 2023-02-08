////  IDS.swift
//  Barcelona
//
//  Created by Eric Rabil on 9/3/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IDS
import Logging

fileprivate let log = Logger(label: "IDS")

public enum IDStatusError: Error, CustomDebugStringConvertible {
    case malformedID
    
    public var debugDescription: String {
        switch self {
        case .malformedID:
            return "the provided handle ID could not be cast to a destination"
        }
    }
}

public enum IDSState: Int, Codable {
    /// the state has either not been resolved or failed to resolve
    case unknown = 0
    /// this destination can be reached on this service
    case available = 1
    /// this destination can not and will not be reached on this service
    case unavailable = 2
    
    public var isAvailable: Bool {
        self == .available
    }
    
    public init(rawValue: Int) {
        switch rawValue {
        case 1: self = .available
        case 2: self = .unavailable
        default: self = .unknown
        }
    }
    
    public init(rawValue: Int64) {
        self = .init(rawValue: Int(rawValue))
    }
}

extension IDSState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .available: return "available"
        case .unavailable: return "unavailable"
        }
    }
}

public struct BLIDSResolutionOptions: OptionSet {
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public var rawValue: Int
    
    public typealias RawValue = Int
    
    public static let ignoringCache = BLIDSResolutionOptions(rawValue: 1 << 0)
    public static let none: BLIDSResolutionOptions = []
}

class BLIDSIDQueryCache {
    static let shared = BLIDSIDQueryCache()
    
    let defaults = UserDefaults(suiteName: "com.ericrabil.barcelona.id-query")!
    @Atomic private var results: [String: (Date, IDSState)] = [:]
    
    static let queryValidityDuration: TimeInterval = 1 * 60 * 60 * 1.5
    
    func result(for destination: String) -> IDSState? {
        if let (date, result) = results[destination] {
            if abs(date.timeIntervalSinceNow) < Self.queryValidityDuration {
                return result
            }
        }
        if let dict = defaults.dictionary(forKey: destination),
           let date = dict["date"] as? Date,
           abs(date.timeIntervalSinceNow) < Self.queryValidityDuration,
           let result = dict["result"] as? IDSState.RawValue {
            let state = IDSState(rawValue: result)
            results[destination] = (date, state)
            return state
        }
        return nil
    }
    
    func cache(_ result: IDSState, for destination: String, time: Date = Date()) {
        defaults.set([
            "result": result.rawValue,
            "date": time
        ], forKey: destination)
        results[destination] = (time, result)
    }
}

/// Asynchronously resolves the latest IDS status for a set of handles on a given service, defaulting to iMessage.
public func BLResolveIDStatusForIDs(_ ids: [String], onService service: IMServiceStyle, options: BLIDSResolutionOptions = .none, _ callback: @escaping ([String: IDSState]) -> ()) throws {
    var allUnavailable: [String: IDSState] {
        ids.map {
            ($0, IDSState.unavailable)
        }.dictionary(keyedBy: \.0, valuedBy: \.1)
    }
    
    switch service {
    case .SMS:
        guard Registry.sharedInstance.smsServiceEnabled else {
            log.info("Bailing SMS IDS query, sms service is not enabled.")
            return callback(allUnavailable)
        }
        
        return callback(
            ids.map {
                ($0, ($0.isPhoneNumber /*|| $0.isEmail*/) ? IDSState.available : IDSState.unavailable)
            }.dictionary(keyedBy: \.0, valuedBy: \.1)
        )
    case .Phone:
        guard Registry.sharedInstance.callServiceEnabled else {
            log.info("Bailing phone IDS query, calling is not enabled.")
            return callback(allUnavailable)
        }
        
        return callback(
            ids.map {
                ($0, $0.isPhoneNumber ? IDSState.available : IDSState.unavailable)
            }.dictionary(keyedBy: \.0, valuedBy: \.1)
        )
    // only imessage and facetime will return results from IDS
    case .iMessage:
        break
    case .FaceTime:
        break
    }
    
    let destinations = ids.compactMap(\.destination)
    
    if destinations.count != ids.count {
        log.warning("Some IDs are malformed and will not be queried, partial results will be returned")
    }
    
    func FetchLatest(_ destinations: [String], _ callback: @escaping ([String: IDSState]) -> ()) {
        guard destinations.count > 0 else {
            return callback([:])
        }
        
        log.info("Requesting ID status from server for destinations \(destinations.joined(separator: ",")) on service \(service.idsIdentifier)")
        
        IDSIDQueryController.sharedInstance()!.forceRefreshIDStatus(forDestinations: destinations, service: service.idsIdentifier, listenerID: IDSListenerID, queue: HandleQueue) { states in
            let mappedStates = states.mapValues { IDSState(rawValue: $0.intValue) }
            
            log.debug("forceRefreshIDStatus completed with result: \(mappedStates)")
            callback(mappedStates)
        }
    }
    
    if options.contains(.ignoringCache) {
        FetchLatest(destinations) { resolved in
            callback(resolved.mapKeys(\.idsURIStripped))
        }
    } else {
        guard destinations.count > 0 else {
            return callback([:])
        }

        log.info("Requesting ID status from cache for destinations \(destinations.joined(separator: ",")) on service \(service.idsIdentifier)")

        let (cached, uncached) = destinations.splitReduce(intoLeft: [String: IDSState](), intoRight: [String]()) { cached, uncached, destination in
            if let status = BLIDSIDQueryCache.shared.result(for: destination) {
                cached[destination] = status
            } else {
                uncached.append(destination)
            }
        }

        FetchLatest(uncached) { resolved in
            lazy var now = Date()
            callback(resolved.reduce(into: cached) { masterResult, pair in
                BLIDSIDQueryCache.shared.cache(pair.value, for: pair.key, time: now)
                masterResult[pair.key] = pair.value
            }.mapKeys(\.idsURIStripped))
        }
    }
}

/// Synchronously resolves the latest IDS status for a set of handles on a given service.
public func BLResolveIDStatusForIDs(_ ids: [String], onService service: IMServiceStyle, options: BLIDSResolutionOptions = .none) throws -> [String: IDSState] {
    let semaphore = DispatchSemaphore(value: 0)
    var results: [String: IDSState] = [:]
    
    try BLResolveIDStatusForIDs(ids, onService: service, options: options) {
        results = $0
        semaphore.signal()
    }
    
    semaphore.wait()
    
    return results
}

/// Helper variables when processing string IDs into IDS destinations
fileprivate extension String {
    var destination: String? {
        switch style {
        case .email: return IDSCopyIDForEmailAddress(self as CFString)
        case .businessID: return IDSCopyIDForBusinessID(self as CFString)
        case .phoneNumber: return IDSCopyIDForPhoneNumber(self as CFString)
        case .unknown:
            log.warning("\(self) will not be queried because it is an unrecognized address")
            return nil
        }
    }
}

/// Helper functions for processing IDS results
private extension Dictionary {
    func splitFilter(_ check: (Element) -> Bool) -> (included: Dictionary, excluded: Dictionary) {
        var included: Dictionary = [:], excluded: Dictionary = [:]
        
        forEach { element in
            if check(element) {
                included[element.key] = element.value
            } else {
                excluded[element.key] = element.value
            }
        }
        
        return (included, excluded)
    }
    
    func mapKeys<NewKey: Hashable>(_ transform: (Key) throws -> NewKey) rethrows -> [NewKey: Value] {
        var newDictionary: [NewKey: Value] = [:]
        
        try forEach { key, value in
            newDictionary[try transform(key)] = value
        }
        
        return newDictionary
    }
}

private extension String {
    /// Strips the URI prefix that IDS appends to destinations
    var idsURIStripped: String {
        IDSURI(prefixedURI: self)?.unprefixedURI ?? self
    }
}
