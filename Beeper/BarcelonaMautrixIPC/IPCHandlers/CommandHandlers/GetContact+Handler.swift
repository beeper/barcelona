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

extension IMBusinessNameManager {
    func addCallback(forURI uri: String, callback: @escaping (NSString) -> ()) {
        var requests = pendingRequests[uri] as? [Any] ?? []
        requests.append(callback)
        pendingRequests[uri] = requests
    }
}

internal var BMXContactListIsBuilding = false

extension Span {
    var durationString: String {
        "\(context.operation): \((startTimestamp!.distance(to: timestamp!) * 1000).description)ms"
    }
}

public func BMXGenerateContactList(omitAvatars: Bool = false) -> [BLContact] {
    let transaction = SentrySDK.startTransaction(name: "get_contacts", operation: "get_contacts")
    
    BMXContactListIsBuilding = true
    defer { BMXContactListIsBuilding = false }

    let registrar = IMHandleRegistrar.sharedInstance()
    
    var contacts: [BLContact] = [BLContact]()
    
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
        "sortingFamilyName",
        CNContactImageDataAvailableKey
    ] + (omitAvatars ? [] : [CNContactImageDataKey]) as! [CNKeyDescriptor])) { contact, stop in
        // stop here if the contact has no emails or phone numbers
        if contact.emailAddresses.isEmpty && contact.phoneNumbers.isEmpty {
            return
        }
        
        // create a blank collector
        var collector = ContactInfoCollector("")
        collector.omitAvatars = omitAvatars
        
        // collect the base contact information, but dont pull phone or email since we'll do that here
        collector.collect(contact, collectPhoneAndEmail: false)
        
        var handles: [IMHandle] = []
        
        // takes a collection of strings, locates the best handle, collects it, or stores an internationalized transformation of each string
        func process<P: Collection>(handleIDs: P, keyPath: WritableKeyPath<ContactInfoCollector, Set<String>>) where P.Element == String {
            collector[keyPath: keyPath] = handleIDs.reduce(into: collector[keyPath: keyPath]) { addresses, handleID in
                // if there are handles, take either the iMessage handle or the first handle, and collect it
                if let idHandles = registrar.getIMHandles(forID: handleID),
                   let bestHandle = idHandles.first(where: { $0.service == .iMessage() }) ?? idHandles.first {
                    addresses.insert(bestHandle.idWithoutResource)
                    collector.collect(bestHandle, collectContact: false)
                    handles.append(bestHandle)
                // otherwise just internationalize the handleID and insert it
                } else {
                    addresses.insert(preprocessFZID(handleID))
                }
            }
        }
        
        process(handleIDs: contact.phoneNumbers.map(\.value.stringValue), keyPath: \.phoneNumbers)
        process(handleIDs: contact.emailAddresses.map { $0.value as String }, keyPath: \.emailAddresses)
        
        let bestHandle = IMHandle.bestIMHandle(in: handles)
        let bestHandleID = bestHandle?.idWithoutResource ?? (collector.phoneNumbers.first ?? collector.emailAddresses.first)!
        
        collector.fill(handles)
        collector.primaryIdentifier = bestHandleID
        collector.handleID = collector.serviceHint + ";-;" + bestHandleID
        
        contacts.append(collector.finalize())
    }
    
    transaction.setData(value: contacts.count, key: "results_count")
    transaction.finish()
    
    #if DEBUG
    print(transaction.durationString)
    #endif
    
    return contacts
    
}

extension ContactInfoCollector {
    func bestID(includingHandles handles: [IMHandle] = []) -> String? {
        if !handles.isEmpty, let handle = IMHandle.bestIMHandle(in: handles), let id = handle.idWithoutResource {
            return id
        }
        return phoneNumbers.first ?? emailAddresses.first
    }
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

func preprocessFZID(_ fzID: String) -> String {
    if let handle = IMHandleRegistrar.sharedInstance().getIMHandles(forID: fzID)?.first {
        return handle.idWithoutResource
    }
    return IDSDestination(uri: fzID).uri().unprefixedURI
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
    var phoneNumbers: Set<String> = Set()
    var emailAddresses: Set<String> = Set()
    var serviceHint = "SMS"
    
    mutating func collect(_ contact: CNContact, collectPhoneAndEmail: Bool = true) {
        typealias ContactBinding = (WritableKeyPath<Self, String?>, KeyPath<CNContact, String>)
        
        let bindings: [ContactBinding] = [
            (\.firstName, \.givenName),
            (\.lastName, \.familyName),
            (\.nickname, \.nickname),
            (\.suggestedName, \.organizationName)
        ]
        
        for (keyPath, contactKeyPath) in bindings {
            if self[keyPath: keyPath]?.isEmpty != false {
                let contactValue = contact[keyPath: contactKeyPath]
                if !contactValue.isEmpty {
                    self[keyPath: keyPath] = contactValue
                }
            }
        }
        
        if !omitAvatars, avatar?.isEmpty != false, contact.er_imageDataAvailable {
            avatar = contact.imageData
        }
        
        if collectPhoneAndEmail {
            for phoneNumber in contact.phoneNumbers {
                phoneNumbers.insert(preprocessFZID(phoneNumber.value.stringValue))
            }
            
            for emailAddress in contact.emailAddresses {
                emailAddresses.insert(preprocessFZID(emailAddress.value as String))
            }
        }
    }
    
    mutating func collect(_ handle: IMHandle, collectContact: Bool = true) {
        // the service hint is used to decide what goes in the <service>;-;+15555555555 component of the guids. if unchanged it will be SMS
        if handle.service == .iMessage() {
            serviceHint = "iMessage"
        }
        
        if collectContact {
            var criticalFieldsAreEmpty = true
            
            typealias HandleBinding = (WritableKeyPath<Self, Optional<String>>, KeyPath<IMHandle, String?>)
            
            let handleCollectionKeyPaths: [HandleBinding] = [
                (\.firstName, \.firstName),
                (\.lastName, \.lastName),
                (\.nickname, \.nickname)
            ]
            
            for (localKeyPath, handleKeyPath) in handleCollectionKeyPaths {
                if self[keyPath: localKeyPath]?.isEmpty != false {
                    if let handleValue = handle[keyPath: handleKeyPath], !handleValue.isEmpty {
                        self[keyPath: localKeyPath] = handleValue
                    }
                } else {
                    criticalFieldsAreEmpty = false
                }
            }
            
            if criticalFieldsAreEmpty, suggestedName?.isEmpty != false, let handleSuggestedName = handle.suggestedName, !handleSuggestedName.isEmpty {
                suggestedName = handleSuggestedName
            }
            
            if !omitAvatars, avatar == nil {
                avatar = handle.pictureData
            }
            
            if collectContact, let cnContact = handle.cnContact {
                collect(cnContact)
            }
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
    
    static let lawg = Logger(category: "")
    
    var criticalFieldsAreEmpty: Bool {
        let asdf = Self.lawg.operation(named: "mane").begin()
        defer { asdf.end() }
        return firstName?.isEmpty != false && lastName?.isEmpty != false && nickname?.isEmpty != false
    }
    
    mutating func fill(_ handles: [IMHandle]) {
        if criticalFieldsAreEmpty {
            if let suggestedName = suggestedName, !suggestedName.isEmpty {
                firstName = suggestedName
                nickname = nil
                lastName = nil
            } else {
                // search every handle for an IMNickname, merge and break on first occurrence
                for handle in handles {
                    if let imNickname = IMNicknameController.sharedInstance().nickname(for: handle) ?? IMNicknameController.sharedInstance().pendingNicknameUpdates[handle.id] {
                        collect(imNickname)
                        return
                    } else if let formattedPhoneNumber = handle._formattedPhoneNumber() as? String {
                        firstName = formattedPhoneNumber
                        return
                    } else if let displayID = handle.displayID {
                        firstName = displayID
                        return
                    }
                }
            }
        }
    }
    
    mutating func finalize() -> BLContact {
        BLContact (
            first_name: firstName,
            last_name: lastName,
            nickname: nickname,
            avatar: avatar?.base64EncodedString(),
            phones: Array(phoneNumbers),
            emails: Array(emailAddresses),
            user_guid: handleID,
            primary_identifier: primaryIdentifier,
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
