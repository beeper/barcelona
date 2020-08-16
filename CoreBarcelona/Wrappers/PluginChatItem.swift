//
//  PluginChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct PluginChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMTranscriptPluginChatItem, chatGUID: String?) {
        payload = item.dataSource.payload.base64EncodedString()
        bundleID = item.dataSource.bundleID
        
        attachments = []
        
        if let rawAttachments = item.dataSource.pluginPayload?.attachments {
            rawAttachments.forEach {
                let components = $0.pathComponents
                let guid = components[components.count - 2]
                guard let attachment = AttachmentRepresentation(guid: guid) else {
                    return
                }
                
                attachments.append(attachment)
            }
        }
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var payload: String
    var bundleID: String
    var attachments: [AttachmentRepresentation]
}
