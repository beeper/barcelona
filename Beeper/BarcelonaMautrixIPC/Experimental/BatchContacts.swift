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
        public func run(payload: IPCPayload) {
            GetContactListResponse.loadInBackground { response in
                autoreleasepool {
                    payload.reply(withCommand: .contacts(response))
                }
            }
        }
    }
    
    public static func loadInBackground(_ callback: @escaping (GetContactListResponse) -> ()) {
        DispatchQueue.global(qos: .utility).async {
            let list = BMXGenerateContactList(omitAvatars: true, asyncLookup: true)
            callback(GetContactListResponse(contacts: list))
        }
    }
    
    public init() {
        contacts = BMXGenerateContactList()
    }
    
    public init(contacts: [BLContact]) {
        self.contacts = contacts
    }
    
    public var contacts: [BLContact]
}
