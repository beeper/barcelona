//
//  CreatePluginMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMSharedUtilities

private extension String {
    func substring(trunactingFirst prefix: Int) -> Substring {
        self.suffix(from: self.index(startIndex, offsetBy: prefix))
    }
    
    func nsRange(of string: String) -> NSRange {
        (self as NSString).range(of: string)
    }
    
    var isBusinessBundleID: Bool {
        self == "com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension"
    }
}

private extension NSAttributedString {
    func range(of string: String) -> NSRange {
        self.string.nsRange(of: string)
    }
}

public struct CreatePluginMessage: Codable, CreateMessageBase {
    public init(extensionData: MessageExtensionsData, attachmentID: String? = nil, bundleID: String, expressiveSendStyleID: String? = nil, threadIdentifier: String? = nil, replyToPart: String? = nil) {
        self.extensionData = extensionData
        self.attachmentID = attachmentID
        self.bundleID = bundleID
        self.expressiveSendStyleID = expressiveSendStyleID
        self.threadIdentifier = threadIdentifier
        self.replyToPart = replyToPart
    }
    
    public var extensionData: MessageExtensionsData
    public var attachmentID: String?
    public var bundleID: String
    public var expressiveSendStyleID: String?
    public var threadIdentifier: String?
    public var replyToPart: String?
    
    public func parseToAttributed() -> MessagePartParseResult {
        ERAttributedString(forExtensionOptions: self)
    }
    
    public func createIMMessageItem(withThreadIdentifier threadIdentifier: String?, withChatIdentifier chatIdentifier: String, withParseResult parseResult: MessagePartParseResult) throws -> (IMMessageItem, NSMutableAttributedString?) {
        var payloadData = extensionData
        payloadData.data = payloadData.data ?? payloadData.synthesizedData
        
        let messageString = NSMutableAttributedString(attributedString: parseResult.string)
        messageString.append(.init(string: IMBreadcrumbCharacterString))
        
        messageString.addAttributes([
            MessageAttributes.writingDirection: -1,
            MessageAttributes.breadcrumbOptions: 0,
            MessageAttributes.breadcrumbMarker: extensionData.layoutInfo?.caption ?? "Message Extension"
        ], range: messageString.range(of: IMBreadcrumbCharacterString))
        
        let messageItem = IMMessageItem.init(sender: nil, time: nil, guid: nil, type: 0)!
        
        messageItem.body = messageString
        messageItem.balloonBundleID = bundleID
        messageItem.payloadData = payloadData.archive
        messageItem.flags = 5
        
        ERApplyMessageExtensionQuirks(toMessageItem: messageItem, inChatID: chatIdentifier, forOptions: self)
        
        return (messageItem, nil)
    }
}
