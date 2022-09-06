//
//  BatchContacts.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 4/8/22.
//

import Foundation
import Barcelona
import IMCore
import BarcelonaMautrixIPCProtobuf

public struct PBContactList {
    public struct Runner: Runnable {
        public func run(payload: IPCPayload) {
            payload.reply(withResponse: .contacts(.with {
                $0.contacts = BMXGenerateContactList(omitAvatars: true)
            }))
        }
    }
}
