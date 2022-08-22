//
//  IMChat+Acknowledgment.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import Swog
import IMSharedUtilities

private let chatItemGUIDExtractor = try! NSRegularExpression(pattern: "(?:\\w+:\\d+)\\/([\\w-]+)")

public extension IMChat {
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails. This must be invoked on the main thread.
     */
    func tapback(message: IMMessage, itemGUID: String, type: Int, overridingItemType: UInt8?, metadata: Message.Metadata? = nil) throws -> IMMessage {
        guard Thread.isMainThread else {
            preconditionFailure("IMChat.tapback() must be invoked on the main thread")
        }
        
        if itemGUID == message.id, let subpart = message.subpart(at: 0) {
            return try tapback(message: message, itemGUID: subpart.id, type: type, overridingItemType: overridingItemType)
        }
        
        guard let subpart = message.subpart(with: itemGUID) as? IMMessagePartChatItem else {
            throw BarcelonaError(code: 404, message: "Unknown subpart")
        }
        
        let rawType = Int64(type)
        
//        sendMessageAcknowledgment(Int64(type), forChatItem: subpart, withMessageSummaryInfo: )
        guard let summaryInfo = subpart.summaryInfo(for: message, in: self, itemTypeOverride: overridingItemType), let compatibilityString = IMMessageAcknowledgmentStringHelper.generateBackwardCompatibilityString(forMessageAcknowledgmentType: rawType, messageSummaryInfo: summaryInfo), let superFormat = IMCreateSuperFormatStringFromPlainTextString(compatibilityString) else {
            throw BarcelonaError(code: 500, message: "Internal server error")
        }
        
        let adjustedSummaryInfo = IMChat.__im_adjustMessageSummaryInfo(forSending: summaryInfo)
        let guid = subpart.guid
        let range = subpart.messagePartRange
        
        var message: IMMessage!
        
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            message = IMMessage.instantMessage(withAssociatedMessageContent: superFormat, flags: 0, associatedMessageGUID: guid, associatedMessageType: rawType, associatedMessageRange: range, messageSummaryInfo: adjustedSummaryInfo, threadIdentifier: nil)
        } else {
            message = IMMessage.instantMessage(withAssociatedMessageContent: superFormat, flags: 0, associatedMessageGUID: guid, associatedMessageType: rawType, associatedMessageRange: range, messageSummaryInfo: adjustedSummaryInfo)
        }
        
        guard message != nil else {
            throw BarcelonaError(code: 500, message: "Couldn't create tapback message")
        }
        
        if let metadata = metadata {
            message.metadata = metadata
        }
        
        send(message)
        
        return message
    }
    
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails
     */
    func tapback(guid: String, itemGUID: String, type: Int, overridingItemType: UInt8?, metadata: Message.Metadata? = nil) throws -> IMMessage {
        guard let message = BLLoadIMMessage(withGUID: guid) else {
            throw BarcelonaError(code: 404, message: "Unknown message: \(guid)")
        }
        
        return try self.tapback(message: message, itemGUID: itemGUID, type: type, overridingItemType: overridingItemType, metadata: metadata)
    }
}
