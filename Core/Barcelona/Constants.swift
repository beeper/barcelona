//
//  Constants.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

/// Imma be real witchu idk why this is the attachment string but IMCore uses this
let IMAttachmentString = String(data: Data(base64Encoded: "77+8")!, encoding: .utf8)!

/// flag |= MessageModifier
enum MessageModifiers: UInt64 {
    case expirable = 0x1000005
}

let ERChatMessageReceivedNotification = NSNotification.Name(rawValue: "ERChatMessageReceivedNotification")
let ERChatMessagesReceivedNotification = NSNotification.Name(rawValue: "ERChatMessagesReceivedNotification")
let BLChatMessageSentNotification = NSNotification.Name(rawValue: "BLChatMessageSentNotification")
let ERChatMessagesUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessagesUpdatedNotification")
let ERChatMessageUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessageUpdatedNotification")
let ERChatMessagesDeletedNotification = NSNotification.Name(rawValue: "ERChatMessagesDeletedNotification")

let ERDefaultMessageQueryLimit: Int = 75
