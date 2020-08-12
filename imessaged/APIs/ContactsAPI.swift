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

struct ContactIDRepresentation: Content {
    var id: String
}

struct ContactRepresentation: Content, Comparable {
    static func < (lhs: ContactRepresentation, rhs: ContactRepresentation) -> Bool {
        guard let lhsFullName = lhs.fullName else { return false }
        guard let rhsFullName = rhs.fullName else { return true }
        return lhsFullName < rhsFullName
    }
    
    static func == (lhs: ContactRepresentation, rhs: ContactRepresentation) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(_ contact: CNContact) {
        self.id = contact.identifier
        self.firstName = contact.givenName.count == 0 ? nil : contact.givenName
        self.middleName = contact.middleName.count == 0 ? nil : contact.middleName
        self.lastName = contact.familyName.count == 0 ? nil : contact.familyName
        self.fullName = CNContactFormatter.string(from: contact, style: .fullName)
        self.nickname = contact.nickname.count == 0 ? nil : contact.nickname
        self.hasPicture = contact.thumbnailImageData != nil
        
        self.handles = contact.phoneNumbers.reduce(into: contact.emailAddresses.reduce(into: []) { (result, email) in
            result.append(HandleRepresentation(id: email.value as String, isBusiness: false))
        }) { (result, phoneNumber) in
            guard let countryCode = phoneNumber.value.value(forKey: "countryCode") as? String, let phoneNumber = phoneNumber.value.value(forKey: "digits") as? String else {
                return
            }
            guard let normalized = IMNormalizedPhoneNumberForPhoneNumber(phoneNumber, countryCode, true) as? String else {
                return
            }
            result.append(HandleRepresentation(id: "+\(normalized)", isBusiness: false))
        }
    }
    
    var id: String
    var firstName: String?
    var middleName: String?
    var lastName: String?
    var fullName: String?
    var nickname: String?
    var countryCode: String?
    var hasPicture: Bool
    var handles: [HandleRepresentation]
    
    var empty: Bool {
        return (fullName?.count ?? 0) == 0
    }
    
    mutating func addHandle(_ handle: HandleRepresentation) {
        if handles.contains(handle) {
            return
        }
        handles.append(handle)
    }
}

struct BulkContactRepresentation: Content {
    var contacts: [ContactRepresentation]
    var strangers: [HandleRepresentation]
}

public func bindContactsAPI(_ app: Application) {
    let contacts = app.grouped("contacts")
    
    contacts.get { req -> EventLoopFuture<BulkContactRepresentation> in
        let search = try? req.query.get(String.self, at: "search")
        let limit = try? req.query.get(Int.self, at: "limit")
        
        return req.eventLoop.makeSucceededFuture(IMContactStore.shared.representations(matching: search, limit: limit))
    }
    
    let contact = contacts.grouped(":id")
    
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
