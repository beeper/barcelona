//
//  GetContacts+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMFoundation
import IMSharedUtilities
import IMCore
import Barcelona
import SwiftyContacts
import Sentry
import IDS
import Pwomise
import Swog

extension IMBusinessNameManager {
    func addCallback(forURI uri: String, callback: @escaping (NSString) -> ()) {
        var requests = pendingRequests[uri] as? [Any] ?? []
        requests.append(callback)
        pendingRequests[uri] = requests
    }
}

internal var BMXContactListIsBuilding = false
@usableFromInline internal var BMXContactListDebug = false

internal let BMXContactListTrace = Tracer(Logger(category: "BMXContactList"), BMXContactListDebug)

/// Prewarms the correlation data for all URIs currently in the contact store
public func BMXPrewarm() -> Promise<TimeInterval> {
    let uris = Array(BMXGenerateURIList()), uriCount = uris.count
    let start = Date()
    return Array(stride(from: uris.startIndex, to: uris.endIndex, by: 25)).serial { start in
        CBSenderCorrelationController.shared.prewarm(senders: Array(uris[start..<min(uriCount, start + 25)])).resolving(on: DispatchQueue.global())
    }.then { _ in
        abs(start.timeIntervalSinceNow)
    }
}

private extension IMHandle {
    var mautrixID: String {
        let id = id
        if isLoginIMHandleForAnyAccount, id.hasPrefix("e:") || id.hasPrefix("E:") {
            return String(id.dropFirst(2))
        }
        return id
    }
}

public func BMXGenerateURIList() -> Set<String> {
    var collector = URICollector()
    try! CNContactStore().enumerateContacts(with: CNContactFetchRequest(keysToFetch: [
        CNContactEmailAddressesKey,
        CNContactPhoneNumbersKey
    ] as! [CNKeyDescriptor])) { contact, stop in
        collector.collect(contact)
    }
    return collector.uris
}

public func BMXGenerateContactList(omitAvatars: Bool = false, asyncLookup: Bool = false) -> [BLContact] {
    let transaction = SentrySDK.startTransaction(name: "get_contacts", operation: "get_contacts")
    
    BMXContactListIsBuilding = true
    defer { BMXContactListIsBuilding = false }
    var finalized: [BLContact] = []
    var collector = ContactInfoCollector("")
    collector.omitAvatars = omitAvatars
    try! CNContactStore().enumerateContacts(with: CNContactFetchRequest(keysToFetch: [
        CNContactIdentifierKey,
        CNContactEmailAddressesKey,
        CNContactPhoneNumbersKey,
        CNContactGivenNameKey,
        CNContactFamilyNameKey,
        CNContactOrganizationNameKey,
        CNContactNicknameKey,
        CNContactImageDataAvailableKey
    ] + (omitAvatars ? [] : [CNContactImageDataKey]) as! [CNKeyDescriptor])) { contact, stop in
        if let contact = BLContact.blContact(for: contact, collector: &collector) {
            finalized.append(contact)
        }
    }
    let filtered = finalized.filter { !$0.user_guid.isEmpty }
    transaction.setTag(value: NSUserName(), key: "sessionID")
    transaction.setData(value: filtered.count, key: "loadedCount")
    transaction.finish(status: .ok)
    return filtered
}

extension CNContact {
    var er_imageDataAvailable: Bool {
        guard isKeyAvailable(CNContactImageDataAvailableKey) else {
            if isKeyAvailable(CNContactImageDataKey) {
                return imageData != nil
            }
            return false
        }
        return imageDataAvailable
    }
}

struct URICollector {
    var uris: Set<String> = Set()
    var phoneNumbers: Set<String> = Set()
    var emailAddresses: Set<String> = Set()
    
    mutating func collect(_ contact: CNContact) {
        for phoneNumber in contact.phoneNumbers {
            let unformatted = phoneNumber.value.unformattedInternationalStringValue()
            phoneNumbers.insert(unformatted)
            uris.insert("tel:\(unformatted)")
        }
        
        for emailAddress in contact.emailAddresses.lazy.map({ $0.value as String }) {
            emailAddresses.insert(emailAddress)
            uris.insert("mailto:\(emailAddress)")
        }
    }
    
    mutating func reset(keepingCapacity: Bool = false) {
        uris.removeAll(keepingCapacity: keepingCapacity)
        phoneNumbers.removeAll(keepingCapacity: keepingCapacity)
        emailAddresses.removeAll(keepingCapacity: keepingCapacity)
    }
}

struct ContactInfoCollector {
    var handleID: String
    var omitAvatars: Bool = false
    
    init(_ handleID: String) {
        self.handleID = handleID
    }
    
    var primaryIdentifier: String?
    var firstName: String?
    var lastName: String?
    var nickname: String?
    var suggestedName: String?
    var avatar: Data?
    var uriCollector: URICollector = URICollector()
    var serviceHint = "SMS"
    var correlationID: String?
    
    var contacts: Set<CNContact> = Set()
    var handles: Set<IMHandle> = Set()
    
    mutating func reset() {
        handleID = ""
        primaryIdentifier = nil
        firstName = nil
        lastName = nil
        nickname = nil
        suggestedName = nil
        avatar = nil
        uriCollector.reset(keepingCapacity: true)
        serviceHint = "SMS"
        contacts.removeAll(keepingCapacity: true)
        handles.removeAll(keepingCapacity: true)
        correlationID = nil
    }
    
    mutating func collect(_ contact: CNContact) {
        contacts.insert(contact)
        
        if firstName?.isEmpty != false {
            firstName = contact.givenName
        }

        if lastName?.isEmpty != false {
            lastName = contact.familyName
        }

        if nickname?.isEmpty != false {
            nickname = contact.nickname
        }

        if suggestedName?.isEmpty != false {
            suggestedName = contact.organizationName
        }
        
        if !omitAvatars, avatar?.isEmpty != false, contact.er_imageDataAvailable {
            avatar = contact.imageData
        }
        
        uriCollector.collect(contact)
    }
    
    mutating func collect(_ handle: IMHandle, checkContact: Bool = true) {
        handles.insert(handle)
        
        if checkContact, firstName?.isEmpty != false {
            firstName = handle.firstName
        }
        
        if checkContact, lastName?.isEmpty != false {
            lastName = handle.lastName
        }
        
        if checkContact, nickname?.isEmpty != false {
            nickname = handle.nickname
        }
        
        if suggestedName?.isEmpty != false {
            suggestedName = handle.suggestedName
        }
        
        if !omitAvatars, avatar == nil {
            avatar = handle.pictureData
        }
        
        // the service hint is used to decide what goes in the <service>;-;+15555555555 component of the guids. if unchanged it will be SMS
        if handle.service == .iMessage() {
            serviceHint = "iMessage"
        }
        
        if checkContact, let cnContact = handle.cnContact {
            collect(cnContact)
        }
    }
    
    mutating func collect(_ imNickname: IMNickname) {
        firstName = imNickname.firstName
        lastName = imNickname.lastName
        nickname = imNickname.displayName
        
        if !omitAvatars, avatar?.isEmpty != false {
            avatar = imNickname.avatar.imageData()
        }
    }
    
    var criticalFieldsAreEmpty: Bool {
        firstName?.isEmpty != false && lastName?.isEmpty != false && nickname?.isEmpty != false
    }
    
    mutating func finalize(assertCorrelationID: Bool = false) -> BLContact {
        if criticalFieldsAreEmpty {
            if let suggestedName = suggestedName {
                firstName = suggestedName
                nickname = nil
                lastName = nil
            } else {
                // search every handle for an IMNickname, merge and break on first occurrence
                for handle in handles {
                    if let imNickname = IMNicknameController.sharedInstance().nickname(for: handle) ?? IMNicknameController.sharedInstance().pendingNicknameUpdates[handle.id] {
                        collect(imNickname)
                        break
                    }
                }
            }
        }
        
        if criticalFieldsAreEmpty {
            firstName = handles.compactMap(\.name).first
        }
        
        BMXContactListTrace("lookup correlation ID for \(uriCollector.uris.count) uris") {
            correlationID = CBSenderCorrelationController.shared.correlate(sameSenders: Array(uriCollector.uris), offline: !assertCorrelationID)
        }
        
        let contact = BLContact (
            first_name: firstName,
            last_name: lastName,
            nickname: nickname,
            avatar: avatar?.base64EncodedString(),
            phones: Array(uriCollector.phoneNumbers),
            emails: uriCollector.emailAddresses.map { IMFormattedDisplayStringForID($0, nil) ?? $0 },
            user_guid: handleID,
            primary_identifier: primaryIdentifier,
            serviceHint: serviceHint,
            correlation_id: correlationID
        )
        
        reset()
        
        return contact
    }
}

extension BLContact {
    public static func blContact(for contact: CNContact) -> BLContact? {
        var collector = ContactInfoCollector("")
        return blContact(for: contact, collector: &collector)
    }
    
    static func blContact(for contact: CNContact, collector: inout ContactInfoCollector) -> BLContact? {
        if contact.phoneNumbers.isEmpty && contact.emailAddresses.isEmpty {
            return nil
        }
        let handles = IMHandle.handles(for: contact)
        BMXContactListTrace("collect contact \(contact.id)") {
            collector.collect(contact)
        }
        handles.forEach { handle in
            BMXContactListTrace("collect handle \(handle.id)") {
                collector.collect(handle, checkContact: false)
            }
        }
        guard let id = (IMHandle.bestIMHandle(in: handles) ?? handles.first)?.mautrixID ?? collector.uriCollector.phoneNumbers.first ?? collector.uriCollector.emailAddresses.first else {
            collector.reset()
            return nil
        }
        collector.primaryIdentifier = id
        collector.handleID = collector.serviceHint + ";-;" + id
        return BMXContactListTrace("finalize contact \(contact.id)") { collector.finalize() }
    }
    
    public static func blContact(forHandleID handleID: String, assertCorrelationID: Bool = false) -> BLContact {
        if handleID.isBusinessID {
            if let handle = IMHandle.resolve(withIdentifier: handleID) {
                // mapItemImageData was replaced with a brandSquareLogoImageData in Monterey, in order to integrate with BusinessServices.framework. this can be removed once big sur support is dropped (if ever)
                return BLContact(first_name: handle.name, last_name: nil, nickname: nil, avatar: handle.businessPhotoData?.base64EncodedString(), phones: [], emails: [], user_guid: handle.id, serviceHint: "iMessage")
            } else {
                return BLContact(first_name: nil, last_name: nil, nickname: nil, avatar: nil, phones: [], emails: [], user_guid: handleID, serviceHint: "iMessage")
            }
        } else {
            var collector: ContactInfoCollector = ContactInfoCollector(handleID)
            
            do {
                var contacts: [CNContact]
                
                if handleID.isPhoneNumber {
                    contacts = try SwiftyContacts.fetchContacts(matching: CNPhoneNumber(stringValue: handleID))
                } else {
                    contacts = try SwiftyContacts.fetchContacts(matchingEmailAddress: handleID)
                }
                
                for contact in contacts {
                    collector.collect(contact)
                }
            } catch {
                CLWarn("ContactInfo", "Failed to query contacts: \(String(describing: error), privacy: .public)")
            }
            
            if let handles = IMHandleRegistrar.sharedInstance().getIMHandles(forID: handleID) {
                for handle in handles {
                    collector.collect(handle)
                }
            }
            
            return collector.finalize(assertCorrelationID: assertCorrelationID)
        }
    }
}

extension GetContactCommand: Runnable {
    public func run(payload: IPCPayload) {
        payload.respond(.contact(BLContact.blContact(forHandleID: normalizedHandleID, assertCorrelationID: true)))
    }
}
