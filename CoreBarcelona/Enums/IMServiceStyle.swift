//
//  IMServiceStyle.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

public enum IMServiceStyle: String, CaseIterable, Codable {
    case iMessage
    #if IDS_IMESSAGE_BIZ
    case iMessageBiz
    #endif
    case SMS
    case FaceTime
    case Phone
    case None
    
    public var service: IMServiceImpl? {
        switch self {
        #if IDS_IMESSAGE_BIZ
        case .iMessageBiz:
            fallthrough
        #endif
        case .iMessage:
            return IMService.iMessage() as? IMServiceImpl
        case .Phone:
            return IMService.call() as? IMServiceImpl
        case .FaceTime:
            return IMService.facetime() as? IMServiceImpl
        case .SMS:
            return IMService.sms() as? IMServiceImpl
        case .None:
            return nil
        }
    }
    
    public var account: IMAccount? {
        guard let service = service else { return nil }
        return IMAccountController.sharedInstance().bestAccount(forService: service)
    }
    
    public static var services: [IMServiceImpl] {
        allCases.compactMap {
            $0.service
        }
    }
}
