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

let ERChatMessageReceivedNotification = NSNotification.Name(rawValue: "ERChatMessageReceivedNotification")
let ERChatMessagesReceivedNotification = NSNotification.Name(rawValue: "ERChatMessagesReceivedNotification")
