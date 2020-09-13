//
//  HandlesAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import CommunicationsFilter
import Foundation
import Vapor
import IMCore
import IDS

protocol BulkHandleIDRepresentable {
    var handles: [String] { get set }
}

struct BulkHandleIDRepresentation: Content, BulkHandleIDRepresentable {
    var handles: [String]
}


let LoadBlockList = {
    BulkHandleIDRepresentation(handles: ERSharedBlockList().copyAllItems()!.compactMap { $0.unformattedID })
}

internal extension IMServiceStyle {
    func status(withState state: IDSState) -> IDSStatus {
        IDSStatus(service: self, available: state.isAvailable)
    }
}

internal extension String {
    var service: IMService? {
        Registry.sharedInstance.resolve(service: self)
    }
}

extension Array where Element == IMServiceStyle {
    func idStatuses(forHandles handles: [String]) -> EventLoopFuture<[IDSStatuses]> {
        /// Takes the array of IMServices, and attempts to resolve the IDS states for the given handles
        return EventLoopFuture<[IMServiceStyle: [String: IDSState]]>.whenAllSucceed(self.compactMap { style in
            guard let account = style.account, let service = style.idsIdentifier else {
                return nil
            }
            
            return handles.compactMap { handleID in
                account.imHandle(withID: handleID)
            }.lazyIDStatuses(onService: service).map {
                [style: $0]
            }
        /// Takes the array of resolved states and reduces them into pairs of handle ID / array of statuses
        }, on: messageQuerySystem.next()).map { availabilities in
            return availabilities.reduce(into: [String: [IDSStatus]]()) { ledger, statuses in
                statuses.forEach { entry in
                    let style = entry.key, serviceStatuses = entry.value
                    
                    serviceStatuses.forEach { statusEntry in
                        let id = statusEntry.key, state = statusEntry.value
                        
                        if ledger[id] == nil {
                            ledger[id] = []
                        }
                        
                        ledger[id]?.append(style.status(withState: state))
                    }
                }
            }.map {
                IDSStatuses(handle: $0.key, services: $0.value)
            }
        }
    }
}

internal let HandleQueue = DispatchQueue.init(label: "HandleIDS")

struct IDSStatus: Codable {
    var service: IMServiceStyle
    var available: Bool
}

struct IDSStatuses: Codable {
    var handle: String
    var services: [IDSStatus]
}

struct BulkIDSStatuses: Codable {
    var statuses: [IDSStatuses]
}

extension BulkIDSStatuses: Content { }

/** Manages handles */
internal func bindHandlesAPI(_ app: Application) {
    let handles = app.grouped("handles")
    
    // MARK: - IDS
    
    handles.get("ids") { req -> EventLoopFuture<BulkIDSStatuses> in
        guard let handleIDs = try? req.query.get([String].self, at: "handles") else {
            throw Abort(.badRequest, reason: "Handle must be supplied.")
        }

        return IMServiceStyle.allCases.idStatuses(forHandles: handleIDs).map {
            BulkIDSStatuses(statuses: $0)
        }
    }
    
    // MARK: - Blocklist
    
    /** Manages the block list */
    let blocked = handles.grouped("blocked")
    
    /** Get all blocked users */
    blocked.get { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        return req.eventLoop.makeSucceededFuture(LoadBlockList())
    }
    
    let specific = blocked.grouped(":handle")
    
    /**
     Block a set of users
     */
    specific.put { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        guard let handleID = req.parameters.get("handle") else {
            throw Abort(.badRequest)
        }
        
        ERSharedBlockList().addItem(forAllServices: CreateCMFItemFromString(handleID))
        
        return req.eventLoop.makeSucceededFuture(LoadBlockList())
    }
    
    specific.delete { req -> EventLoopFuture<BulkHandleIDRepresentation> in
        guard let handleID = req.parameters.get("handle") else {
            throw Abort(.badRequest)
        }
        
        ERSharedBlockList().removeItem(forAllServices: CreateCMFItemFromString(handleID))
        
        return req.eventLoop.makeSucceededFuture(LoadBlockList())
    }
}
