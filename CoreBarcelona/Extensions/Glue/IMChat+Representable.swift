//
//  IMChat+Representable.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public extension IMChat {
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
    
    var groupPhotoID: String? {
        get {
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                return value(forChatProperty: IMGroupPhotoGuidKey) as? String
            } else {
                return nil
            }
        }
        set {
            if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                setValue(newValue, forChatProperty: IMGroupPhotoGuidKey)
                sendGroupPhotoUpdate(newValue)
            }
        }
    }
    
    var properties: ChatConfigurationRepresentation {
        ChatConfigurationRepresentation(id: id, readReceipts: readReceipts, ignoreAlerts: ignoreAlerts, groupPhotoID: groupPhotoID)
    }
    
    var representableParticipantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participantHandleIDs())
    }
}
