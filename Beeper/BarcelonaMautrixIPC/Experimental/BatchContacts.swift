//
//  BatchContacts.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 4/8/22.
//

import Foundation
import Barcelona
import IMCore

public struct GetContactListResponse: Codable {
    public struct Runner: Runnable {
        public func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel) {
            payload.reply(withResponse: .contacts(GetContactListResponse(contacts: BMXGenerateContactList(omitAvatars: true))), ipcChannel: ipcChannel)
        }
    }
    
    public init(contacts: [BLContact]) {
        self.contacts = contacts
    }
    
    public var contacts: [BLContact]
}
