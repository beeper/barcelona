//
//  ContactsAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import IMCore
import IMSharedUtilities
import Foundation
import Vapor

public func bindContactsAPI(_ app: Application) {
    let contacts = app.grouped("contacts")
    
    // MARK: - Bulk
    contacts.get { req -> EventLoopFuture<BulkContactRepresentation> in
        let search = try? req.query.get(String.self, at: "search")
        let limit = try? req.query.get(Int.self, at: "limit")
        
        return req.eventLoop.makeSucceededFuture(IMContactStore.shared.representations(matching: search, limit: limit))
    }
    
    // MARK: - Specific contact
    let contact = contacts.grouped(CNContactMiddleware).grouped(":\(CNContactResourceKey)")
    
    /**
     Get contact info
     */
    contact.get { req -> Contact in
        req.contact
    }
    
    /**
     Get contact photo
     */
    contact.get("photo") { req -> Response in
        let size = try? req.query.get(Int.self, at: "size")
        
        guard let thumbnail = req.cnContact.thumbnailImage(size: size) else {
            throw Abort(.notFound, reason: "missing thumbnail")
        }
        
        let parts = thumbnail.mime.split(separator: "/")
        
        let response = Response()
        response.headers.contentType = HTTPMediaType(type: String(parts[0]), subType: String(parts[1]))
        response.body = .init(data: thumbnail.data)
        return response
    }
}
