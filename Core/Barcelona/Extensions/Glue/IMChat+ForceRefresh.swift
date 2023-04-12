//
//  IMChat+ForceRefresh.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/2/22.
//

import Foundation
import IMCore
import Logging

extension IMChat {
    /// Returns true if the next message sent will be sent over SMS
    public var willSendSMS: Bool {
        account.service?.id == .SMS
    }

    /// Returns true if there are data inconsistencies warranting a service refresh
    public var forceRefresh: Bool {
        if isSingle && willSendSMS && recipient?.id.isEmail == true {
            return true
        }
        return false
    }

    // Call to ensure that all handles are being watched so that we don't miss any mesages from them
    @available(macOS 13.0, *)
    public func watchAllHandles() {
        beginObservingHandleAvailability()

        guard let participants else {
            log.warning("Chat \(String(describing: self.guid)) participants is nil, can't watch them", source: "IMChat")
            return
        }

        // Watch all the people who are in the chat
        participants.forEach(account.startWatchingIMHandle)
    }
}
