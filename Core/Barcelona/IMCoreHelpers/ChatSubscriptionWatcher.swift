//
//  ERChatSubscriptionWatcher.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import UserNotifications
import Foundation
import IMCore

private let IMChatRegistryDidLoadNotification = NSNotification.Name(rawValue: "__kIMChatRegistryDidLoadNotification")
private let IMChatRegistryDidRegisterChatNotification = NSNotification.Name(rawValue: "__kIMChatRegistryDidRegisterChatNotification")

public func CBLoadBlocklist() -> BulkHandleIDRepresentation {
    BulkHandleIDRepresentation(handles: ERSharedBlockList().copyAllItems()!.compactMap { $0.unformattedID })
}
