//
//  IMChat+Representable.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChat {
    var representation: Chat {
        Chat(self)
    }
    
    var readReceipts: Bool {
        get {
            value(forChatProperty: "EnableReadReceiptForChat") as? Bool ?? false
        }
        set {
            setValue(newValue == true ? 1 : 0, forChatProperty: "EnableReadReceiptForChat")
        }
    }
    
    var ignoreAlerts: Bool {
        get {
            value(forChatProperty: "ignoreAlertsFlag") as? Bool ?? false
        }
        set {
            setValue(newValue == true ? 1 : 0, forChatProperty: "ignoreAlertsFlag")
        }
    }
    
    var properties: ChatConfigurationRepresentation {
        ChatConfigurationRepresentation(id: id, readReceipts: readReceipts, ignoreAlerts: ignoreAlerts)
    }
    
    var representableParticipantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participantHandleIDs())
    }
}
