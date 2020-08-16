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

protocol BulkHandleIDRepresentable {
    var handles: [String] { get set }
}

struct BulkHandleIDRepresentation: Content, BulkHandleIDRepresentable {
    var handles: [String]
}


let LoadBlockList = {
    BulkHandleIDRepresentation(handles: ERSharedBlockList().copyAllItems()!.compactMap { $0.unformattedID })
}

/** Manages handles */
public func bindHandlesAPI(_ app: Application) {
    let handles = app.grouped("handles")
    
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
