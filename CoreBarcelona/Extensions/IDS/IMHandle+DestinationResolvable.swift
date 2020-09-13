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
import NIO

internal enum HandleIDStyle {
    case email
    case businessID
    case phoneNumber
    case unknown
}

extension Array where Element == IMServiceStyle {
    var services: [IMServiceImpl] {
        compactMap {
            $0.service
        }
    }
}

enum IDSState: Int, Codable {
    case unknown = 0
    case available = 1
    case unavailable = 2
    
    var isAvailable: Bool {
        self == .available
    }
    
    init(rawValue: Int) {
        switch rawValue {
        case 1: self = .available
        case 2: self = .unavailable
        default: self = .unknown
        }
    }
}

extension Array where Element == IMHandle {
    var destinations: [IDSDestination] {
        compactMap {
            $0.destination
        }
    }
    
    /// Returns a dictionary of [HandleID: IDSState] values
    var idStatuses: [String: IDSState] {
        reduce(into: [String: IDSState]()) { ledger, handle in
            let isSMS = handle.service?.id == .some(IMServiceStyle.SMS), isPhoneNumber = handle.isPhoneNumber
            
            let unconditionallyAvailable = isSMS && isPhoneNumber
            
            /// If this is a phone number and the SMS service, it is always available. Otherwise, wrap the status into an IDSState
            ledger[handle.id] = unconditionallyAvailable ? .available : .init(rawValue: Int(handle.cachedIdStatus))
        }
    }
    
    /// Computes IDS statuses for handles that have not been loaded yet, otherwise returning the cached values
    func lazyIDStatuses(onService service: String? = nil) -> EventLoopFuture<[String: IDSState]> {
        let unresolved = filter {
            if let service = service {
                return $0.cachedIdStatusOverridden(withIDSService: service) == 0
            }
            
            return $0.cachedIdStatus == 0
        }
        
        let promise = messageQuerySystem.next().makePromise(of: Void.self)
        
        if unresolved.count > 0, let queryController = IDSIDQueryController.sharedInstance(), let service = service ?? unresolved[0].service?.idsServiceName {
            queryController.refreshIDStatus(forDestinations: destinations, service: service, listenerID: IDSListenerID, queue: HandleQueue, completionBlock: {
                promise.succeed(())
            })
        } else {
            promise.succeed(())
        }
        
        return promise.futureResult.map {
            self.idStatuses
        }
    }
}

/// Helper variables when processing string IDs into IDS destinations
internal extension String {
    var isEmail: Bool {
        IMStringIsEmail(self as CFString)
    }
    
    var isBusinessID: Bool {
        IMStringIsBusinessID(self as CFString)
    }
    
    var isPhoneNumber: Bool {
        IMStringIsPhoneNumber(self as CFString)
    }
    
    var style: HandleIDStyle {
        switch true {
        case isEmail: return .email
        case isPhoneNumber: return .phoneNumber
        case isBusinessID: return .businessID
        default: return .unknown
        }
    }
    
    var destination: IDSDestination? {
        switch style {
        case .email: return IDSCopyIDForEmailAddress(self as CFString)
        case .businessID: return IDSCopyIDForBusinessID(self as CFString)
        case .phoneNumber: return IDSCopyIDForPhoneNumber(self as CFString)
        case .unknown: return nil
        }
    }
}

extension IMService: Equatable {
    public static func == (lhs: IMService, rhs: IMService) -> Bool {
        return (lhs as? IMServiceImpl)?.internalName == (rhs as? IMServiceImpl)?.internalName
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
    func lazyIDStatus(on eventLoop: EventLoop! = nil) -> EventLoopFuture<Int64> {
        let eventLoop = eventLoop ?? messageQuerySystem.next(), cachedIdStatus = self.cachedIdStatus
        
        /// 0 means it hasn't been loaded, 1 means it is available, 2 means it is unavailable. if it is not 0, return the value
        if cachedIdStatus != 0 {
            return eventLoop.makeSucceededFuture(cachedIdStatus)
        }
        
        /// IDS whats good?!
        return refreshIDStatus(on: eventLoop)
    }
    
    /// unconditionally queries IDS for the status of this handle
    func refreshIDStatus(on eventLoop: EventLoop! = nil) -> EventLoopFuture<Int64> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        
        /// ensure this handle can actually be queried against IDS
        guard let destination = destination, let serviceName = idsServiceName, let queryController = IDSIDQueryController.sharedInstance() else {
            return eventLoop.makeSucceededFuture(IMHandleUnknownIDStatus)
        }
        
        let promise = eventLoop.makePromise(of: Int64.self)
        
        /// query IDS and convert completion to a promise
        queryController.refreshIDStatus(forDestination: destination, service: serviceName, listenerID: IDSListenerID, queue: HandleQueue, completionBlock: {
            promise.succeed(self.cachedIdStatus)
        })
        
        return promise.futureResult
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
