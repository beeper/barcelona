//
//  ContactsAPI.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import IMCore
import IMSharedUtilities
import CoreBarcelona
import Foundation
import Vapor

public func bindContactsAPI(_ app: RoutesBuilder) {
    let contacts = app.grouped("contacts")
    let readableContacts = contacts.grouped(TokenGrant.readContacts)
    let writableContacts = contacts.grouped(TokenGrant.writeContacts)
    
    // MARK: - Bulk
    readableContacts.get { _ -> BulkContactRepresentation in
        IMContactStore.shared.representations()
    }
    
    // MARK: - Specific contact
    let contact = contacts.grouped(CNContactMiddleware).grouped(":\(CNContactResourceKey)")
    let readableContact = contact.grouped(TokenGrant.readContacts)
    let writableContact = contact.grouped(TokenGrant.writeContacts)
    
    /**
     Get contact info
     */
    readableContact.get { req -> Contact in
        req.contact
    }
    
    /**
     Get contact photo
     */
    readableContact.get("photo") { req -> Response in
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

