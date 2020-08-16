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
    let contact = contacts.grouped(":id")
    
    /**
     Get contact info
     */
    contact.get { req -> EventLoopFuture<ContactRepresentation> in
        guard let cnID = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        
        let promise = req.eventLoop.makePromise(of: ContactRepresentation.self)
        
        req.eventLoop.submit {
            do {
                let store = IMContactStore.sharedInstance()!.contactStore!
                let registrar = IMHandleRegistrar.sharedInstance()!
                
                let contact = try store.unifiedContact(withIdentifier: cnID, keysToFetch: CNContactStore.defaultKeysToFetch)
                
                var representation = ContactRepresentation(contact)
                
                registrar.handles(forCNIdentifier: contact.identifier).forEach { representation.addHandle(HandleRepresentation($0)) }
                
                
                promise.succeed(representation)
            } catch {
                if let error = error as? CNError {
                    if error.code == .recordDoesNotExist {
                        promise.fail(Abort(.notFound))
                        return
                    }
                }
                print("failed to load contact! \(error)")
                promise.fail(Abort(.internalServerError))
            }
        }
        
        return promise.futureResult
    }
    
    /**
     Get contact photo
     */
    contact.get("photo") { req -> EventLoopFuture<Response> in
        guard let cnID = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        
        let promise = req.eventLoop.makePromise(of: Response.self)
        
        req.eventLoop.submit {
            do {
                let store = IMContactStore.sharedInstance()!.contactStore!
                
                let contact = try store.unifiedContact(withIdentifier: cnID, keysToFetch: CNContactStore.defaultKeysToFetch)
                
                let size = try? req.query.get(Int.self, at: "size")
                
                guard let thumbnail = contact.thumbnailImage(size: size) else {
                    promise.fail(Abort(.notFound))
                    return
                }
                
                let parts = thumbnail.mime.split(separator: "/")
                
                let response = Response()
                response.headers.contentType = HTTPMediaType(type: String(parts[0]), subType: String(parts[1]))
                response.body = .init(data: thumbnail.data)
                promise.succeed(response)
            } catch {
                if let error = error as? CNError {
                    if error.code == .recordDoesNotExist {
                        promise.fail(Abort(.notFound))
                        return
                    }
                }
                print("failed to load contact! \(error)")
                promise.fail(Abort(.internalServerError))
            }
        }
        
        return promise.futureResult
    }
}
