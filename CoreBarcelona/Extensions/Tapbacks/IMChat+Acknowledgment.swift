//
//  IMChat+Acknowledgment.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import NIO

private let chatItemGUIDExtractor = try! NSRegularExpression(pattern: "(?:\\w+:\\d+)\\/([\\w-]+)")

public extension IMChat {
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails
     */
    func tapback(message: IMMessage, itemGUID: String, type: Int, overridingItemType: UInt8?) -> EventLoopFuture<IMMessage> {
        guard let subpart = message.subpart(with: itemGUID) as? IMMessagePartChatItem else {
            return messageQuerySystem.next().makeFailedFuture(BarcelonaError(code: 404, message: "Not found"))
        }
        
        let rawType = Int64(type)
        
//        sendMessageAcknowledgment(Int64(type), forChatItem: subpart, withMessageSummaryInfo: )
        guard let summaryInfo = subpart.summaryInfo(for: message, in: self, itemTypeOverride: overridingItemType), let compatibilityString = IMMessageAcknowledgmentStringHelper.generateBackwardCompatibilityString(forMessageAcknowledgmentType: rawType, messageSummaryInfo: summaryInfo), let superFormat = IMCreateSuperFormatStringFromPlainTextString(compatibilityString) else {
            return messageQuerySystem.next().makeFailedFuture(BarcelonaError(code: 500, message: "Internal server error"))
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
            return messageQuerySystem.next().makeFailedFuture(BarcelonaError(code: 500, message: "Couldn't create tapback message"))
        }
        
        let promise = messageQuerySystem.next().makePromise(of: IMMessage.self);
    
        DispatchQueue.main.async {
            self.sendMessage(message)
            
            promise.succeed(message)
        }
        
        return promise.futureResult
    }
    
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails
     */
    func tapback(guid: String, itemGUID: String, type: Int, overridingItemType: UInt8?) -> EventLoopFuture<IMMessage> {
        return IMMessage.imMessage(withGUID: guid).flatMap {
            guard let message = $0 else {
                return messageQuerySystem.next().makeFailedFuture(BarcelonaError(code: 404, message: "Unknown message"))
            }
            
            return self.tapback(message: message, itemGUID: itemGUID, type: type, overridingItemType: overridingItemType)
        }
    }
}
