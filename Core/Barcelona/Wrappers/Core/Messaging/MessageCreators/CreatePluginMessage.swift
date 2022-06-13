//
//  CreatePluginMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMSharedUtilities
import IMCore

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

/// Replaces all IMLinkAttributeName values with parsed URLs
public func ERRepairAttributedLinkString(_ link: NSAttributedString) -> NSAttributedString? {
    let copy = link.mutableCopy() as! NSMutableAttributedString
    var mutated = false
    link.enumerateAttribute(MessageAttributes.link, in: link.wholeRange) { value, range, stop in
        switch value {
        case is URL, is NSURL:
            break
        default:
            copy.removeAttribute(MessageAttributes.link, range: range)
            if let string = value as? String, let url = URL(string: string) {
                mutated = true
                copy.addAttribute(MessageAttributes.link, value: url, range: range)
            }
        }
    }
    guard mutated else {
        return nil
    }
    return NSAttributedString(attributedString: copy)
}

import IMDaemonCore
import Sentry
import Swog

/// For rich link messages, repairs their attributed string by replacing all IMLinkAttributeName:NSString to IMLinkAttributeName:NSURL
public func ERRepairIMMessageItem(_ message: IMMessageItem) -> IMMessageItem {
    guard message.balloonBundleID == IMBalloonPluginIdentifierRichLinks else {
        return message
    }
    guard let text = message.body, let repaired = ERRepairAttributedLinkString(text) else {
        CLInfo("ERRepairIMMessage", "Not repairing message %@", message.guid)
        return message
    }
    message.body = repaired
    let newMessageItem = IMDMessageStore.sharedInstance().storeMessage(message, forceReplace: true, modifyError: false, modifyFlags: false, flagMask: 0, updateMessageCache: true, calculateUnreadCount: false)
    CLInfo("ERRepairIMMessage", "Repaired corrupted rich link message with GUID %@", message.guid)
    SentrySDK.capture(message: "Repaired corrupted rich link message") { scope in
        scope.setTag(value: "guid", key: message.guid)
    }
    return newMessageItem
}

public func ERCreateBlankRichLinkMessage(_ text: String, _ url: URL, _ initializer: (IMMessageItem) -> () = { _ in }) -> IMMessage {
    let messageItem = IMMessageItem.init(sender: nil, time: nil, guid: nil, type: 0)!
    
    messageItem.service = IMServiceStyle.iMessage.rawValue
    
    let messageString = NSMutableAttributedString(attributedString: .init(string: text))

    messageString.addAttributes([
        MessageAttributes.writingDirection: -1,
        MessageAttributes.link: url
    ], range: messageString.range(of: text))
    
    messageItem.body = messageString
    messageItem.balloonBundleID = "com.apple.messages.URLBalloonProvider"
    messageItem.payloadData = Data()
    messageItem.flags = 5
    initializer(messageItem)
    
    return IMMessage.message(fromUnloadedItem: messageItem)!
}

public struct CreatePluginMessage: Codable, CreateMessageBase {
    public init(extensionData: MessageExtensionsData, attachmentID: String? = nil, bundleID: String, expressiveSendStyleID: String? = nil, threadIdentifier: String? = nil, replyToGUID: String? = nil, replyToPart: Int? = nil) {
        self.extensionData = extensionData
        self.attachmentID = attachmentID
        self.bundleID = bundleID
        self.expressiveSendStyleID = expressiveSendStyleID
        self.threadIdentifier = threadIdentifier
        self.replyToGUID = replyToGUID
        self.replyToPart = replyToPart
    }
    
    public var extensionData: MessageExtensionsData
    public var attachmentID: String?
    public var bundleID: String
    public var expressiveSendStyleID: String?
    public var threadIdentifier: String?
    public var replyToPart: Int?
    public var replyToGUID: String?
    
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
        
        #if false
        ERApplyMessageExtensionQuirks(toMessageItem: messageItem, inChatID: chatIdentifier, forOptions: self)
        #endif
        
        return (messageItem, nil)
    }
}
