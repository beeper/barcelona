//
//  IMServiceStyle.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

// (bl-api-exposed)
/// Different styles of IMCore services
public enum IMServiceStyle: String, CaseIterable, Codable, Hashable, Sendable {
    case iMessage
    #if IDS_IMESSAGE_BIZ
    case iMessageBiz
    #endif
    case SMS
    case FaceTime
    case Phone

    public var service: IMServiceImpl {
        switch self {
        #if IDS_IMESSAGE_BIZ
        case .iMessageBiz:
            fallthrough
        #endif
        case .iMessage:
            return IMService.iMessage()
        case .Phone:
            return IMService.call()
        case .FaceTime:
            return IMService.facetime()
        case .SMS:
            return IMService.sms()
        }
    }

    public var account: IMAccount? {
        IMAccountController.shared.bestAccount(forService: service)
    }

    public var handle: IMHandle? {
        Registry.sharedInstance.suitableHandle(for: service)
    }
}
