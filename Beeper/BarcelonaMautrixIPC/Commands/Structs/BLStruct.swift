//
//  BLStruct.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation

/// Need to update the enums codable data? Paste the cases at the top into BLStruct.codegen.js and then paste the output of that below the CodingKeys declaration
public enum BLStruct {
    case message(BLMessage)
    case messageStatus(BLMessageStatus)
    case partialMessage(BLPartialMessage)
    case attachment(BLAttachment)
    case associatedMessage(BLAssociatedMessage)
    case readReceipt(BLReadReceipt)
    case typing(BLTypingNotification)
    case chat(BLChat)
    case contact(BLContact)
}
