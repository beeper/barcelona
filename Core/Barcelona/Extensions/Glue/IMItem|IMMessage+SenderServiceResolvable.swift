//
//  IMItem|IMMessage+SenderServiceResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaDB
import Foundation
import IDS
import IMCore
import IMSharedUtilities

internal func CBResolveSenderHandle(originalHandle: String?, isFromMe: Bool, service: IMServiceStyle) -> String? {
    guard isFromMe else {
        return originalHandle
    }

    switch service {
    case .iMessage:
        return nil
    case .FaceTime:
        return nil
    default:
        return Registry.sharedInstance.suitableHandle(for: service.service)?.idWithoutResource
    }
}

extension IMMessage {
    func resolveSenderID(inService service: IMServiceStyle) -> String? {
        CBResolveSenderHandle(
            originalHandle: sender?.idWithoutResource,
            isFromMe: isFromMe,
            service: service
        )
    }
}

extension IMItem {
    func resolveSenderID(inService service: IMServiceStyle) -> String? {
        CBResolveSenderHandle(originalHandle: sender, isFromMe: isFromMe, service: service)
    }
}
