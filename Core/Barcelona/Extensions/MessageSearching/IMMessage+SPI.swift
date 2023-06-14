//
//  IMMessage+SPI.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 8/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import os.log

extension IMMessage {
    /**
     Takes an IMMessageItem that has no context object and resolves it into a fully formed IMMessage
     */
    public static func message(
        fromUnloadedItem item: IMMessageItem,
        withSubject subject: NSMutableAttributedString?,
        service: IMServiceStyle
    ) -> IMMessage? {
        var rawSender: String? = item.resolveSenderID(inService: service)

        if item.sender() == nil, item.isFromMe(),
            let suitableHandle = Registry.sharedInstance.suitableHandle(for: item.service)
        {
            rawSender = suitableHandle.id
            item.accountID = suitableHandle.account.uniqueID
        }

        guard let senderID = rawSender, let account = item.imAccount,
            let sender = Registry.sharedInstance.imHandle(withID: senderID, onAccount: account)
        else {
            return nil
        }

        return IMMessage(fromIMMessageItem: item, sender: sender, subject: subject)!
    }

    public static func message(fromUnloadedItem item: IMMessageItem, service: IMServiceStyle) -> IMMessage? {
        message(fromUnloadedItem: item, withSubject: nil, service: service)
    }
}
