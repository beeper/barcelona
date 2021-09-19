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

extension GetContactCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let contact = blContact else {
            let formatted = IMFormattedDisplayStringForID(normalizedHandleID, nil) ?? normalizedHandleID
            
            return payload.respond(.contact(BLContact(first_name: nil, last_name: nil, nickname: nil, avatar: nil, phones: normalizedHandleID.isPhoneNumber ? [formatted] : [], emails: normalizedHandleID.isEmail ? [formatted] : [], user_guid: user_guid)))
        }
        
        payload.respond(.contact(contact))
    }
}
