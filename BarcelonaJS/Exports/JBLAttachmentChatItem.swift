//
//  JBLAttachmentChatItem.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import JavaScriptCore

@objc
public protocol JBLAttachmentChatItemExports: JBLChatItemExports, JSExport {
    var fileTransferID: String { get set }
    var attachment: JBLAttachmentJSExports? { get set }
}

@objc
public class JBLAttachmentChatItem: JBLChatItem, JBLAttachmentChatItemExports {
    public var fileTransferID: String
    public var attachment: JBLAttachmentJSExports?
    
    public init(item: AttachmentChatItem) {
        fileTransferID = item.transferID
        if let metadata = item.metadata {
            attachment = JBLAttachment(attachment: metadata)
        }
        super.init(item: item)
    }
}
