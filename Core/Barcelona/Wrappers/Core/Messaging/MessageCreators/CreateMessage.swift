//
//  CreateMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMSharedUtilities
import IMCore

private func additionalFlags(forCreation creation: CreateMessage) -> IMMessageFlags {
    if let _ = creation.ballonBundleID { return .hasDDResults }
    if let audio = creation.isAudioMessage { if audio { return [.expirable, .audioMessage] } }
    return []
}

public enum MessagePartType: String, Codable {
    case text
    case attachment
    case breadcrumb
}

public struct MessagePart: Codable {
    public var type: MessagePartType
    public var details: String
    public var attributes: [TextPartAttribute]?
    
    public init(type: MessagePartType, details: String, attributes: [TextPartAttribute]? = nil) {
        self.type = type
        self.details = details
        self.attributes = attributes
    }
}

public struct TapbackCreation: Codable {
    public var item: String
    public var message: String
    public var type: Int
    
    public init(item: String, message: String, type: Int) {
        self.item = item
        self.message = message
        self.type = type
    }
}

public struct CreateMessage: Codable, CreateMessageBase {
    public init(subject: String? = nil, parts: [MessagePart], isAudioMessage: Bool? = nil, flags: CLongLong? = nil, ballonBundleID: String? = nil, payloadData: String? = nil, expressiveSendStyleID: String? = nil, threadIdentifier: String? = nil, replyToPart: Int? = nil, replyToGUID: String? = nil) {
        self.subject = subject
        self.parts = parts
        self.isAudioMessage = isAudioMessage
        self.flags = flags
        self.ballonBundleID = ballonBundleID
        self.payloadData = payloadData
        self.expressiveSendStyleID = expressiveSendStyleID
        self.threadIdentifier = threadIdentifier
        self.replyToPart = replyToPart
        self.replyToGUID = replyToGUID
    }
    
    public var subject: String?
    public var parts: [MessagePart]
    public var isAudioMessage: Bool?
    public var flags: CLongLong?
    public var ballonBundleID: String?
    public var payloadData: String?
    public var expressiveSendStyleID: String?
    public var threadIdentifier: String?
    public var replyToGUID: String?
    public var replyToPart: Int?
    
    public func parseToAttributed() -> MessagePartParseResult {
        ERAttributedString(from: self.parts)
    }
    
    static let baseFlags: IMMessageFlags = [
        .finished, .fromMe, .delivered, .sent, .dataDetected
    ]
    
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
        messageItem.flags = Self.baseFlags.union(additionalFlags(forCreation: self)).rawValue
        
        return (messageItem, subject)
    }
}
