//
//  BarcelonaJS.swift
//  BarcelonaJS
//
//  Created by Eric Rabil on 8/11/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
@_exported import BarcelonaJSFoundation
import Swog

@_cdecl("JBLCreateJSContext")
public func JBLCreateJSContext() -> JSContext {
    JSContextCreateBaseContextWithAPIs { context in
        [
            JBLChat.self,
            JBLMessage.self,
            JBLChatItem.self,
            JBLAttachmentChatItem.self,
            JBLTextChatItem.self,
            JBLStatusChatItem.self,
            JBLAcknowledgmentChatItem.self,
            JBLAttachment.self,
            JBLEventBus(context: context),
            JBLAccount.self,
            JBLContact.self
        ]
    }
}
