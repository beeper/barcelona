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
    init(_ item: IMAttachmentMessagePartChatItem, chatGUID: String?) {
        transferGUID = item.transferGUID
        metadata = AttachmentRepresentation(guid: transferGUID)
        self.load(item: item, chatGUID: chatGUID)
    }
    
    var guid: String?
    var chatGUID: String?
    var fromMe: Bool?
    var time: Double?
    var transferGUID: String
    var metadata: AttachmentRepresentation?
}
