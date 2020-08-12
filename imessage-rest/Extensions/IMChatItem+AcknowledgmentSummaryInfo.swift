//
//  IMChatItem+AcknowledgmentSummaryInfo.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChatItem {
    /**
     Creates summary info relevant for a tapback message
     */
    func summaryInfo(for message: IMMessage, in chat: IMChat, itemTypeOverride: UInt8? = nil) -> Any? {
        let description = message.description(forPurpose: 0x1, inChat: chat)
        
        var summary: Any? = nil
        var itemType: TapBackSpecificItemType = .text
        var pluginDisplayName: String? = nil
        
        if let tapbackData = IMBalloonPluginManager.extractTapbackInformationForMessage(message) {
            itemType = .plugin
            summary = tapbackData.summary
            pluginDisplayName = tapbackData.pluginDisplayName
        } else {
            if message.isAudioMessage { itemType = .audioMessage }
            
            if let attachment = self as? IMAttachmentMessagePartChatItem {
                itemType = attachment.tapBackType
            }
        }
        
        if let override = itemTypeOverride {
            itemType = TapBackSpecificItemType.init(rawValue: override) ?? itemType
        }
        
        return NSDictionary.dictionary(withAssociatedMessageSummary: summary ?? description, contentType: (itemType.rawValue) & 0xff, pluginBundleID: message.balloonBundleID, pluginDisplayName: pluginDisplayName)
    }
}
