//
//  IMServiceStyle+IDSIdentifier.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IDS

extension IMServiceStyle {
    public var idsIdentifier: String {
        switch self {
        case .iMessage: return IDSServiceNameiMessage
        #if IDS_IMESSAGE_BIZ
        case .iMessageBiz: return IDSServiceNameiMessageForBusiness
        #endif
        case .SMS: return IDSServiceNameSMSRelay
        case .Phone: return IDSServiceNameCalling
        case .FaceTime: return IDSServiceNameFaceTime
        }
    }
}
