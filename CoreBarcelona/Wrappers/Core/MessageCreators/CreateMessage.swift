//
//  CreateMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import NIO
import IMSharedUtilities

private func flagsForCreation(_ creation: CreateMessage, transfers: [String]) -> FullFlagsFromMe {
    if let _ = creation.ballonBundleID { return .richLink }
    if let audio = creation.isAudioMessage { if audio { return .audioMessage } }
    if transfers.count > 0 || creation.parts.contains(where: { $0.type == .attachment }) { return .attachments }
    return .textOrPluginOrStickerOrImage
}

public struct CreateMessage: Codable, CreateMessageBase {
    public var subject: String?
    public var parts: [MessagePart]
    public var isAudioMessage: Bool?
    public var flags: CLongLong?
    public var ballonBundleID: String?
    public var payloadData: String?
    public var expressiveSendStyleID: String?
    public var threadIdentifier: String?
    public var replyToPart: String?
    
    public func parseToAttributed(on eventLoop: EventLoop)  -> EventLoopFuture<MessagePartParseResult> {
        ERAttributedString(from: self.parts, on: eventLoop)
    }
    
    public func createIMMessageItem(withThreadIdentifier threadIdentifier: String?, withChatIdentifier chatIdentifier: String, withParseResult parseResult: MessagePartParseResult) throws -> (IMMessageItem, NSMutableAttributedString?) {
        let text = parseResult.string
        let fileTransferGUIDs = parseResult.transferGUIDs
        
        if text.length == 0 {
            throw BarcelonaError(code: 400, message: "Cannot send an empty message")
        }
        
        var subject: NSMutableAttributedString?
        
        if let rawSubject = self.subject {
            subject = NSMutableAttributedString(string: rawSubject)
        }
        
        /** Creates a base message using the computed attributed string */
        
        let messageItem = IMMessageItem.init(sender: nil, time: nil, guid: nil, type: 0)!
        messageItem.body = text
        messageItem.flags = flagsForCreation(self, transfers: fileTransferGUIDs).rawValue
        
        return (messageItem, subject)
    }
}
