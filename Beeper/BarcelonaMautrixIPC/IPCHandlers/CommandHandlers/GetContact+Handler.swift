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

extension IMHandle {
    var __businessImage: Data? {
        CBSelectLinkingPath([
            [.preMonterey]: {
                self.mapItemImageData
            },
            [.monterey]: {
                self.brandSquareLogoImageData()
            }
        ])?()
    }
    
    var blContactForBusiness: BLContact {
        BLContact(first_name: name, last_name: nil, nickname: nil, avatar: __businessImage?.base64EncodedString(), phones: [], emails: [], user_guid: id)
    }
}

extension GetContactCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let contact = blContact else {
            let formatted = IMFormattedDisplayStringForID(normalizedHandleID, nil) ?? normalizedHandleID
            
            if normalizedHandleID.isBusinessID, let handle = IMHandle.resolve(withIdentifier: normalizedHandleID) {
                payload.respond(.contact(handle.blContactForBusiness))
                
                return
            }
            
            return payload.respond(.contact(BLContact(first_name: nil, last_name: nil, nickname: nil, avatar: nil, phones: normalizedHandleID.isPhoneNumber ? [formatted] : [], emails: normalizedHandleID.isEmail ? [formatted] : [], user_guid: user_guid)))
        }
        
        payload.respond(.contact(contact))
    }
}
