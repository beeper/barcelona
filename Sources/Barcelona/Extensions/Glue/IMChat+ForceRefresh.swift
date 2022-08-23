//
//  IMChat+ForceRefresh.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/2/22.
//

import Foundation
import IMCore

public extension IMChat {
    /// Returns true if the next message sent will be sent over SMS
    var willSendSMS: Bool {
        account?.service?.id == .SMS
    }
    
    /// Returns true if there are data inconsistencies warranting a service refresh
    var forceRefresh: Bool {
        if isSingle && willSendSMS && recipient?.id.isEmail == true {
            return true
        }
        return false
    }
}
