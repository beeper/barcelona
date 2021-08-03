//
//  IMChat+Acknowledgment.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/5/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

private let chatItemGUIDExtractor = try! NSRegularExpression(pattern: "(?:\\w+:\\d+)\\/([\\w-]+)")

public extension IMChat {
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails
     */
    func tapback(message: IMMessage, itemGUID: String, type: Int, overridingItemType: UInt8?) -> Promise<IMMessage> {
        if itemGUID == message.id, let subpart = message.subpart(at: 0) {
            return tapback(message: message, itemGUID: subpart.id, type: type, overridingItemType: overridingItemType)
        }
        
        guard let subpart = message.subpart(with: itemGUID) as? IMMessagePartChatItem else {
            return .failure(BarcelonaError(code: 404, message: "Not found"))
        }
        
        let rawType = Int64(type)
        
//        sendMessageAcknowledgment(Int64(type), forChatItem: subpart, withMessageSummaryInfo: )
        guard let summaryInfo = subpart.summaryInfo(for: message, in: self, itemTypeOverride: overridingItemType), let compatibilityString = IMMessageAcknowledgmentStringHelper.generateBackwardCompatibilityString(forMessageAcknowledgmentType: rawType, messageSummaryInfo: summaryInfo), let superFormat = IMCreateSuperFormatStringFromPlainTextString(compatibilityString) else {
            return .failure(BarcelonaError(code: 500, message: "Internal server error"))
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
            return .failure(BarcelonaError(code: 500, message: "Couldn't create tapback message"))
        }
        
        return RunLoop.main.promise {
            self.sendMessage(message)
            
            return message
        }
    }
    
    /**
     Sends a tapback for a given message, calling back with a Vapor abort if the operation fails
     */
    func tapback(guid: String, itemGUID: String, type: Int, overridingItemType: UInt8?) -> Promise<IMMessage> {
        return IMMessage.lazyResolve(withIdentifier: guid)
            .assert(BarcelonaError(code: 404, message: "Unknown message"))
            .then { message -> Promise<IMMessage> in
                self.tapback(message: message, itemGUID: itemGUID, type: type, overridingItemType: overridingItemType)
            }
    }
}
