//
//  IMChat+Representable.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/9/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

private let IMChatPropertyGroupPhotoGUID: NSString? = CBWeakLink(
    against: .privateFramework(name: "IMSharedUtilities"),
    options: [
        .symbol("IMGroupPhotoGuidKey").bigSur.preMonterey,
        .symbol("IMChatPropertyGroupPhotoGUID").monterey,
    ]
)

extension IMChat: ChatConfigurationRepresentable {

    public var id: String {
        chatIdentifier
    }

    public var readReceipts: Bool {
        get {
            value(forChatProperty: "EnableReadReceiptForChat") as? Bool ?? false
        }
        set {
            setValue(newValue == true ? 1 : 0, forChatProperty: "EnableReadReceiptForChat")
        }
    }

    public var ignoreAlerts: Bool {
        get {
            value(forChatProperty: "ignoreAlertsFlag") as? Bool ?? false
        }
        set {
            setValue(newValue == true ? 1 : 0, forChatProperty: "ignoreAlertsFlag")
        }
    }

    public var groupPhotoID: String? {
        get {
            IMChatPropertyGroupPhotoGUID.map(value(forChatProperty:)) as? String
        }
        set {
            guard let IMChatPropertyGroupPhotoGUID = IMChatPropertyGroupPhotoGUID
            else {
                return
            }

            setValue(newValue, forChatProperty: IMChatPropertyGroupPhotoGUID)
            sendGroupPhotoUpdate(newValue)
        }
    }
}
