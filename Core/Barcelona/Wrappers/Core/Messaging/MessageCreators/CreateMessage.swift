//
//  CreateMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMSharedUtilities
import Logging

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

public struct CreateMessage: CreateMessageBase {
    public init(
        subject: String? = nil,
        parts: [MessagePart],
        isAudioMessage: Bool? = nil,
        balloonBundleID: String? = nil,
        threadIdentifier: String? = nil,
        replyToPart: Int? = nil,
        replyToGUID: String? = nil,
        metadata: Message.Metadata? = nil
    ) {
        self.subject = subject
        self.isAudioMessage = isAudioMessage
        self.balloonBundleID = balloonBundleID
        self.threadIdentifier = threadIdentifier
        self.replyToPart = replyToPart
        self.replyToGUID = replyToGUID
        self.metadata = metadata

        let parseResult = ERAttributedString(from: parts)
        self.bodyText = parseResult.string
        self.transferGUIDs = parseResult.transferGUIDs
    }

    public var subject: String?
    public var isAudioMessage: Bool?
    public var balloonBundleID: String?
    public var threadIdentifier: String?
    public var replyToGUID: String?
    public var replyToPart: Int?
    public var metadata: Message.Metadata?
    public var bodyText: NSAttributedString
    public var transferGUIDs: [String]
    let payloadData: Data? = nil

    static let baseFlags: IMMessageFlags = [
        .finished, .fromMe, .delivered, .sent, .dataDetected,
    ]

    public var combinedFlags: IMMessageFlags {
        var additionalFlags: IMMessageFlags {
            if balloonBundleID != nil { return .hasDDResults }
            if isAudioMessage == true { return [.expirable, .audioMessage] }
            return []
        }

        return Self.baseFlags.union(additionalFlags)
    }

    public var attributedSubject: NSMutableAttributedString? {
        subject.map { NSMutableAttributedString(string: $0) }
    }
}
