//
//  AttachmentChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/24/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Vapor

struct AttachmentRepresentation: Content {
    init(_ transfer: IMFileTransfer) {
        mime = transfer.mimeType
        filename = transfer.filename
        guid = transfer.guid
        uti = transfer.type
    }
    
    init?(guid: String) {
        guard let item = IMFileTransferCenter.sharedInstance()?.transfer(forGUID: guid, includeRemoved: false) else {
            return nil
        }
        
        self.init(item)
    }
    
    var mime: String?
    var filename: String?
    var guid: String?
    var uti: String?
}

struct AttachmentChatItemRepresentation: Content, ChatItemRepresentation {
    init(_ item: IMAttachmentMessagePartChatItem, metadata attachmentRepresentation: AttachmentRepresentation?, chatGroupID: String?) {
        transferGUID = item.transferGUID
        metadata = attachmentRepresentation
        self.load(item: item, chatGroupID: chatGroupID)
    }
    
    init(_ item: IMAttachmentMessagePartChatItem, chatGroupID: String?) {
        self.init(item, metadata: AttachmentRepresentation(guid: item.transferGUID), chatGroupID: chatGroupID)
    }
    
    var guid: String?
    var chatGroupID: String?
    var fromMe: Bool?
    var time: Double?
    var transferGUID: String
    var metadata: AttachmentRepresentation?
}
