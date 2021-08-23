//
//  GetContacts+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

extension GetContactCommand: Runnable {
    public func run(payload: IPCPayload) {
        guard let contact = blContact else {
            return payload.fail(strategy: .contact_not_found)
        }
        
        payload.respond(.contact(contact))
    }
}
