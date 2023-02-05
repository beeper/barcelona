//
//  Constants.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation

public let HandleQueue = DispatchQueue.init(label: "HandleIDS")

/**
 Imma be real witchu idk why this is the attachment string but IMCore uses this
 */
public let IMAttachmentString = String(data: Data(base64Encoded: "77+8")!, encoding: .utf8)!

internal let IDSListenerID = "SOIDSListener-com.apple.imessage-rest"

/**
 flag |= MessageModifier
 */
public enum MessageModifiers: UInt64 {
    case expirable = 0x1000005
}

public let ERChatMessageReceivedNotification = NSNotification.Name(rawValue: "ERChatMessageReceivedNotification")
public let ERChatMessagesReceivedNotification = NSNotification.Name(rawValue: "ERChatMessagesReceivedNotification")
public let BLChatMessageSentNotification = NSNotification.Name(rawValue: "BLChatMessageSentNotification")
public let ERChatMessagesUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessagesUpdatedNotification")
public let ERChatMessageUpdatedNotification = NSNotification.Name(rawValue: "ERChatMessageUpdatedNotification")
public let ERChatMessagesDeletedNotification = NSNotification.Name(rawValue: "ERChatMessagesDeletedNotification")

public let ERDefaultMessageQueryLimit: Int = 75

public let BLMessageStatusChangedNotification = NSNotification.Name(rawValue: "BLMessageStatusChangedNotification")
