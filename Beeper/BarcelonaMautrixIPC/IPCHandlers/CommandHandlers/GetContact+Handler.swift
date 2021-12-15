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

extension IMBusinessNameManager {
    func addCallback(forURI uri: String, callback: @escaping (NSString) -> ()) {
        var requests = pendingRequests[uri] as? [Any] ?? []
        requests.append(callback)
        pendingRequests[uri] = requests
    }
}

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
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
            let handles = IMHandleRegistrar.sharedInstance().getIMHandles(forID: handleID) ?? []
            
            var firstName: String?, lastName: String?, nickname: String?, suggestedName: String?, avatar: Data?, phoneNumbers = [String](), emailAddresses = [String](), serviceHint: String = "SMS"
            
            for handle in handles {
                if firstName == nil {
                    firstName = handle.firstName
                }
                
                if lastName == nil {
                    lastName = handle.lastName
                }
                
                if nickname == nil {
                    nickname = handle.nickname
                }
                
                if suggestedName == nil {
                    suggestedName = handle.suggestedName
                }
                
                if avatar == nil {
                    avatar = handle.pictureData
                    
                    if avatar == nil, let contact = handle.cnContact {
                        avatar = contact.imageData
                    }
                }
                
                // the service hint is used to decide what goes in the <service>;-;+15555555555 component of the guids. if unchanged it will be SMS
                if handle.service == .iMessage() {
                    serviceHint = "iMessage"
                }
                
                if let cnContact = handle.cnContact {
                    phoneNumbers.append(contentsOf: cnContact.phoneNumbers.map(\.value.stringValue))
                    emailAddresses.append(contentsOf: cnContact.emailAddresses.map { $0.value as String })
                }
            }
            
            if firstName == nil, lastName == nil, nickname == nil {
                if let suggestedName = suggestedName {
                    firstName = suggestedName
                    nickname = nil
                    lastName = nil
                } else {
                    // search every handle for an IMNickname, merge and break on first occurrence
                    for handle in handles {
                        if let imNickname = IMNicknameController.sharedInstance().nickname(for: handle) ?? IMNicknameController.sharedInstance().pendingNicknameUpdates[handle.id] {
                            firstName = imNickname.firstName
                            lastName = imNickname.lastName
                            nickname = imNickname.displayName
                            
                            if avatar == nil {
                                avatar = imNickname.avatar.imageData()
                            }
                            
                            break
                        }
                    }
                }
            }
            
            return BLContact (
                first_name: firstName,
                last_name: lastName,
                nickname: nickname,
                avatar: avatar?.base64EncodedString(),
                phones: phoneNumbers.uniqued().map { IMFormattedDisplayStringForID($0, nil) ?? $0 },
                emails: emailAddresses.uniqued().map { IMFormattedDisplayStringForID($0, nil) ?? $0 },
                user_guid: handleID,
                serviceHint: serviceHint
            )
        }
    }
}

extension GetContactCommand: Runnable {
    public func run(payload: IPCPayload) {
        payload.respond(.contact(BLContact.blContact(forHandleID: normalizedHandleID)))
    }
}
