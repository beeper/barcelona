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

extension IMBusinessNameManager {
    func addCallback(forURI uri: String, callback: @escaping (NSString) -> ()) {
        var requests = pendingRequests[uri] as? [Any] ?? []
        requests.append(callback)
        pendingRequests[uri] = requests
    }
}

internal var BMXContactListIsBuilding = false

public func BMXGenerateContactList(omitAvatars: Bool = false, asyncLookup: Bool = false) -> [BLContact] {
    BMXContactListIsBuilding = true
    defer { BMXContactListIsBuilding = false }
    var contacts: [CNContact] = []
    try! CNContactStore().enumerateContacts(with: CNContactFetchRequest(keysToFetch: [
        CNContactIdentifierKey,
        CNContactEmailAddressesKey,
        CNContactPhoneNumbersKey,
        "linkIdentifier",
        CNContactNamePrefixKey,
        CNContactGivenNameKey,
        CNContactMiddleNameKey,
        CNContactFamilyNameKey,
        CNContactNameSuffixKey,
        CNContactTypeKey,
        CNContactOrganizationNameKey,
        CNContactNicknameKey,
        "displayNameOrder",
        "sortingGivenName",
        "sortingFamilyName"
    ] as! [CNKeyDescriptor])) { contact, stop in
        contacts.append(contact)
    }
    var finalized: [BLContact] = []
    var loadedHandles: [String: [IMHandle]] = [:]
    let semaphore = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .utility).async {
        IMHandle.handles(for: Set(contacts), useBestHandle: false, useExtendedAsyncLookup: asyncLookup) { result in
            loadedHandles = result ?? [:]
            semaphore.signal()
        }
    }
    semaphore.wait()
    DispatchQueue.concurrentPerform(iterations: contacts.count) { index in
        let contact = contacts[index]
        let results = loadedHandles[contact.identifier] ?? []
        var collector = ContactInfoCollector("")
        collector.omitAvatars = omitAvatars
        collector.collect(contact)
        results.forEach { collector.collect($0) }
        guard let id = CBSenderCorrelationController.shared.externalIdentifier(
            from: results,
            phoneNumbers: Array(collector.phoneNumbers),
            emailAddresses: Array(collector.emailAddresses)
        ) else {
            return
        }
        collector.handleID = collector.serviceHint + ";-;" + id
        finalized.append(collector.finalize())
    }
    return finalized
}

struct ContactInfoCollector {
    var handleID: String
    var omitAvatars: Bool = false
    
    init(_ handleID: String) {
        self.handleID = handleID
    }
    
    var firstName: String?
    var lastName: String?
    var nickname: String?
    var suggestedName: String?
    var avatar: Data?
    var phoneNumbers: Set<String> = Set()
    var emailAddresses: Set<String> = Set()
    var serviceHint = "SMS"
    
    var contacts: Set<CNContact> = Set()
    var handles: Set<IMHandle> = Set()
    
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
        
        if !omitAvatars, avatar?.isEmpty != false {
            avatar = contact.imageData
        }
        
        for phoneNumber in contact.phoneNumbers {
            phoneNumbers.insert(phoneNumber.value.stringValue)
        }
        
        for emailAddress in contact.emailAddresses {
            emailAddresses.insert(emailAddress.value as String)
        }
    }
    
    mutating func collect(_ handle: IMHandle) {
        handles.insert(handle)
        
        if firstName?.isEmpty != false {
            firstName = handle.firstName
        }
        
        if lastName?.isEmpty != false {
            lastName = handle.lastName
        }
        
        if nickname?.isEmpty != false {
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
        
        if let cnContact = handle.cnContact {
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
    
    mutating func finalize() -> BLContact {
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
        
        return BLContact (
            first_name: firstName,
            last_name: lastName,
            nickname: nickname,
            avatar: avatar?.base64EncodedString(),
            phones: phoneNumbers.map { IMFormattedDisplayStringForID($0, nil) ?? $0 },
            emails: emailAddresses.map { IMFormattedDisplayStringForID($0, nil) ?? $0 },
            user_guid: handleID,
            serviceHint: serviceHint
        )
    }
}

extension BLContact {
    public static func blContact(forHandleID handleID: String) -> BLContact {
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
            
            return collector.finalize()
        }
    }
}

extension GetContactCommand: Runnable {
    public func run(payload: IPCPayload) {
        payload.respond(.contact(BLContact.blContact(forHandleID: normalizedHandleID)))
    }
}
