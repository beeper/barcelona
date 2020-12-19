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

public struct PluginChatItem: ChatItemRepresentation, ChatItemAcknowledgable {
    init(_ item: IMTranscriptPluginChatItem, chatID: String?) {
        bundleID = item.dataSource.bundleID
        
        os_log("PluginChatItem has fileTransferGUIDs: %@", log: .default, type: .debug, item.fileTransferGUIDs)
        
        attachments = item.attachments
        
        var insertPayload: Bool = true
        
        switch bundleID {
        case "com.apple.DigitalTouchBalloonProvider":
            if let payloadData = item.dataSource?.payload, let digitalTouchMessage = DigitalTouchMessage(data: payloadData) {
                digitalTouch = digitalTouchMessage
            }
            break
        case "com.apple.messages.URLBalloonProvider":
            if let dataSource = item.dataSource, let metadata = dataSource.value(forKey: "richLinkMetadata") as? LPLinkMetadata, let richLink = RichLinkRepresentation(metadata: metadata, attachments: item.internalAttachments) {
                self.richLink = richLink
                insertPayload = false
            }
            break
        default:
            break
        }
        
        if bundleID.starts(with: "com.apple.messages.MSMessageExtensionBalloonPlugin"), let payloadData = item.dataSource?.payload {
            `extension` = MessageExtensionsData(item.dataSource.payload)
            let dict = `extension`?.dictionary
            let archive = `extension`?.archive
            insertPayload = false
        }
        
        if insertPayload {
            payload = item.dataSource.payload?.base64EncodedString()
        }
        
        self.load(item: item, chatID: chatID)
    }
    
    public var id: String?
    public var chatID: String?
    public var fromMe: Bool?
    public var time: Double?
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var digitalTouch: DigitalTouchMessage?
    public var richLink: RichLinkRepresentation?
    public var `extension`: MessageExtensionsData?
    public var payload: String?
    public var bundleID: String
    public var attachments: [Attachment]
    public var acknowledgments: [AcknowledgmentChatItem]?
}
