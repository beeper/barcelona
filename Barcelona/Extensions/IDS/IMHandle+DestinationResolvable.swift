//
//  IMHandle+DestinationResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/10/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMFoundation
import IMCore
import IDS



extension Array where Element == IMServiceStyle {
    var services: [IMServiceImpl] {
        compactMap {
            $0.service
        }
    }
}

public enum IDSState: Int, Codable {
    case unknown = 0
    case available = 1
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
}

public extension Array where Element == IMHandle {
    var destinations: [IDSDestination] {
        compactMap {
            $0.destination
        }
    }
    
    /// Returns a dictionary of [HandleID: IDSState] values
    var idStatuses: [String: IDSState] {
        reduce(into: [String: IDSState]()) { ledger, handle in
            let isSMS = handle.service?.id == .some(IMServiceStyle.SMS), isCall = handle.service?.id == .some(IMServiceStyle.Phone), isPhoneNumber = handle.isPhoneNumber
            
            let unconditionallyAvailable = isPhoneNumber && ((isSMS ? Registry.sharedInstance.smsServiceEnabled : isCall ? Registry.sharedInstance.callServiceEnabled : false) == true)
            
            /// If this is a phone number and the SMS service, it is always available. Otherwise, wrap the status into an IDSState
            let state: IDSState = unconditionallyAvailable ? .available : .init(rawValue: Int(handle.cachedIdStatus))
            
            ledger[handle.id] = state
        }
    }
    
    /// Computes IDS statuses for handles that have not been loaded yet, otherwise returning the cached values
    func lazyIDStatuses(onService service: String? = nil) -> Promise<[String: IDSState]> {
        let unresolved = filter {
            if let service = service {
                return $0.cachedIdStatusOverridden(withIDSService: service) == 0
            }
            
            return $0.cachedIdStatus == 0
        }
        
        if unresolved.count > 0, let queryController = IDSIDQueryController.sharedInstance(), let service = service ?? unresolved[0].service?.idsServiceName {
            return Promise { resolve in
                queryController.refreshIDStatus(forDestinations: destinations, service: service, listenerID: IDSListenerID, queue: HandleQueue, completionBlock: {
                    resolve(self.idStatuses)
                })
            }
        } else {
            return .success(self.idStatuses)
        }
    }
}

/// Helper variables when processing string IDs into IDS destinations
public extension String {
    var destination: IDSDestination? {
        switch style {
        case .email: return IDSCopyIDForEmailAddress(self as CFString)
        case .businessID: return IDSCopyIDForBusinessID(self as CFString)
        case .phoneNumber: return IDSCopyIDForPhoneNumber(self as CFString)
        case .unknown: return nil
        }
    }
}

internal extension IMService {
    /// The unique IDS bundle identifier
    var idsServiceName: String? {
        id.idsIdentifier
    }
}

public let IMHandleUnknownIDStatus: Int64 = -1

public extension IMHandle {
    private var _id: String? {
        self.value(forKey: "ID") as? String
    }
    
    var destination: IDSDestination? {
        guard let ID = _id else {
            return nil
        }
        
        return ID.destination
    }
    
    var isPhoneNumber: Bool {
        guard let ID = _id else {
            return false
        }
        
        return IMStringIsPhoneNumber(ID as CFString)
    }
    
    private var idsServiceName: String? {
        service?.idsServiceName
    }
    
    /// Returns cached ID status if available, otherwise queries IDS.
    func lazyIDStatus() -> Promise<Int64> {
        let cachedIdStatus = self.cachedIdStatus
        
        /// 0 means it hasn't been loaded, 1 means it is available, 2 means it is unavailable. if it is not 0, return the value
        if cachedIdStatus != 0 {
            return .success(cachedIdStatus)
        }
        
        /// IDS whats good?!
        return refreshIDStatus()
    }
    
    /// unconditionally queries IDS for the status of this handle
    func refreshIDStatus() -> Promise<Int64> {
        /// ensure this handle can actually be queried against IDS
        guard let destination = destination, let serviceName = idsServiceName, let queryController = IDSIDQueryController.sharedInstance() else {
            return .success(IMHandleUnknownIDStatus)
        }
        
        return Promise { resolve in
            /// query IDS and convert completion to a promise
            queryController.refreshIDStatus(forDestination: destination, service: serviceName, listenerID: IDSListenerID, queue: HandleQueue, completionBlock: {
                resolve(self.cachedIdStatus)
            })
        }
    }
    
    internal func cachedIdStatusOverridden(withIDSService service: String) -> Int64 {
        /// if this handle is not resolvable against IDS, return unknown
        guard let destination = destination, let queryController = IDSIDQueryController.sharedInstance() else {
            return IMHandleUnknownIDStatus
        }
        
        /// pull cached status from IDS
        return queryController._currentIDStatus(forDestination: destination, service: service, listenerID: IDSListenerID)
    }
    
    var cachedIdStatus: Int64 {
        /// if this handle is not resolvable against IDS, return unknown
        guard let service = idsServiceName else {
            return IMHandleUnknownIDStatus
        }
        
        return cachedIdStatusOverridden(withIDSService: service)
    }
}
