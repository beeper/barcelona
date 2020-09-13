//
//  PluginChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import LinkPresentation
import IMCore
import os.log

struct PluginChatItem: ChatItemRepresentation, ChatItemAcknowledgable {
    init(_ item: IMTranscriptPluginChatItem, chatID: String?) {
        payload = item.dataSource.payload?.base64EncodedString()
        bundleID = item.dataSource.bundleID
        
        os_log("PluginChatItem has fileTransferGUIDs: %@", log: .default, type: .debug, item.fileTransferGUIDs)
        
        attachments = item.attachments
        
        switch bundleID {
        case "com.apple.DigitalTouchBalloonProvider":
            if let payloadData = item.dataSource?.payload, let digitalTouchMessage = DigitalTouchMessage(data: payloadData) {
                digitalTouch = digitalTouchMessage
            }
            break
        case "com.apple.messages.URLBalloonProvider":
            if let dataSource = item.dataSource, let metadata = dataSource.value(forKey: "richLinkMetadata") as? LPLinkMetadata, let richLink = RichLink(metadata: metadata, attachments: item.internalAttachments) {
                self.richLink = richLink
                self.payload = nil
            }
            break
        default:
            break
        }
        
        self.load(item: item, chatID: chatID)
    }
    
    var id: String?
    var chatID: String?
    var fromMe: Bool?
    var time: Double?
    var digitalTouch: DigitalTouchMessage?
    var richLink: RichLink?
    var payload: String?
    var bundleID: String
    var attachments: [Attachment]
    var acknowledgments: [AcknowledgmentChatItem]?
}
