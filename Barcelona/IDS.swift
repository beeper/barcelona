////  IDS.swift
//  Barcelona
//
//  Created by Eric Rabil on 9/3/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IDS

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

/// Asynchronously resolves the latest IDS status for a set of handles on a given service, defaulting to iMessage.
public func BLResolveIDStatusForIDs(_ ids: [String], onService service: IMServiceStyle = IMServiceStyle.iMessage, _ callback: @escaping ([String: IDSState]) -> ()) throws {
    var allUnavailable: [String: IDSState] {
        ids.map {
            ($0, IDSState.unavailable)
        }.dictionary(keyedBy: \.0, valuedBy: \.1)
    }
    
    switch service {
    case .SMS:
        guard Registry.sharedInstance.smsServiceEnabled else {
            return callback(allUnavailable)
        }
        
        return callback(
            ids.map {
                ($0, ($0.isPhoneNumber || $0.isEmail) ? IDSState.available : IDSState.unavailable)
            }.dictionary(keyedBy: \.0, valuedBy: \.1)
        )
    case .Phone:
        guard Registry.sharedInstance.callServiceEnabled else {
            return callback(allUnavailable)
        }
        
        return callback(
            ids.map {
                ($0, $0.isPhoneNumber ? IDSState.available : IDSState.unavailable)
            }.dictionary(keyedBy: \.0, valuedBy: \.1)
        )
    case .None:
        return callback(allUnavailable)
    // only imessage and facetime will return results from IDS
    case .iMessage:
        break
    case .FaceTime:
        break
    }
    
    let destinations = ids.compactMap(\.destination)
    
    guard destinations.count == ids.count else {
        throw IDStatusError.malformedID
    }
    
    // optimization: first check the local cache so we dont consume the IDS rate-limit bucket (its pretty forgiving but still)
    IDSIDQueryController.sharedInstance()!.currentIDStatus(forDestinations: destinations, service: service.idsIdentifier!, listenerID: IDSListenerID, queue: HandleQueue) { cachedResults in
        let cachedResults = cachedResults.mapValues { IDSState(rawValue: $0.intValue) }
        let (needed, resolved) = cachedResults.splitFilter {
            $0.value == .unknown
        }
        
        // all are cached, just return now
        if needed.count == 0 {
            return callback(cachedResults.mapKeys(\.idsURIStripped))
        }
        
        // force IDS to update the remaining destinations
        IDSIDQueryController.sharedInstance()!.forceRefreshIDStatus(forDestinations: Array(needed.keys), service: service.idsIdentifier!, listenerID: IDSListenerID, queue: HandleQueue) {
            let result = $0.mapValues { IDSState(rawValue: $0.intValue) }
            
            // merge new values into the resolved dictionary and return
            callback(result.reduce(into: resolved) { masterResult, pair in
                masterResult[pair.key] = pair.value
            }.mapKeys(\.idsURIStripped))
        }
    }
}

/// Synchronously resolves the latest IDS status for a set of handles on a given service, defaulting to iMessage.
public func BLResolveIDStatusForIDs(_ ids: [String], onService service: IMServiceStyle = IMServiceStyle.iMessage) throws -> [String: IDSState] {
    let semaphore = DispatchSemaphore(value: 0)
    var results: [String: IDSState] = [:]
    
    try BLResolveIDStatusForIDs(ids, onService: service) {
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
        case .unknown: return nil
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
        IDSURI(prefixedURI: self).unprefixedURI()
    }
}
