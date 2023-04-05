//
//  CreatePluginMessage.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 2/17/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import IMDaemonCore
import IMFoundation
import IMSharedUtilities
import Logging
import Sentry

extension String {
    fileprivate func substring(trunactingFirst prefix: Int) -> Substring {
        self.suffix(from: self.index(startIndex, offsetBy: prefix))
    }

    fileprivate func nsRange(of string: String) -> NSRange {
        (self as NSString).range(of: string)
    }

    fileprivate var isBusinessBundleID: Bool {
        self
            == "com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension"
    }
}

extension NSAttributedString {
    fileprivate func range(of string: String) -> NSRange {
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
            if let string = value as? String {
                mutated = true
                let url = URL(string: string) ?? URL(string: ":")!
                copy.addAttribute(MessageAttributes.link, value: url, range: range)
            }
        }
    }
    guard mutated else {
        return nil
    }
    return NSAttributedString(attributedString: copy)
}

/// For rich link messages, repairs their attributed string by replacing all IMLinkAttributeName:NSString to IMLinkAttributeName:NSURL
public func ERRepairIMMessageItem(_ message: IMMessageItem) -> IMMessageItem {
    let log = Logger(label: "ERRepairIMMessageItem")
    guard message.balloonBundleID == IMBalloonPluginIdentifierRichLinks else {
        return message
    }
    guard let text = message.body, let repaired = ERRepairAttributedLinkString(text) else {
        log.info("Not repairing message \(String(describing: message.guid))", source: "ERRepairIMMessage")
        return message
    }
    message.body = repaired
    let newMessageItem = IMDMessageStore.sharedInstance()
        .storeMessage(
            message,
            forceReplace: true,
            modifyError: false,
            modifyFlags: false,
            flagMask: 0,
            updateMessageCache: true,
            calculateUnreadCount: false
        )
    log.info(
        "Repaired corrupted rich link message with GUID \(String(describing: message.guid))",
        source: "ERRepairIMMessage"
    )
    SentrySDK.capture(message: "Repaired corrupted rich link message") { scope in
        scope.setTag(value: "guid", key: message.guid)
    }
    return newMessageItem
}

public func ERCreateBlankRichLinkMessage(
    _ text: String,
    _ url: URL,
    _ initializer: (IMMessageItem) -> Void = { _ in }
) -> IMMessage {
    let messageItem = IMMessageItem.init(sender: nil, time: nil, guid: nil, type: 0)!

    messageItem.service = IMServiceStyle.iMessage.rawValue

    let messageString = NSMutableAttributedString(attributedString: .init(string: text))

    messageString.addAttributes(
        [
            MessageAttributes.writingDirection: -1,
            MessageAttributes.link: url,
        ],
        range: messageString.range(of: text)
    )

    messageItem.body = messageString
    messageItem.balloonBundleID = "com.apple.messages.URLBalloonProvider"
    messageItem.payloadData = Data()
    messageItem.flags = 5
    initializer(messageItem)

    return IMMessage.message(fromUnloadedItem: messageItem)!
}

// public struct CreatePluginMessage: Codable, CreateMessageBase {
public struct CreatePluginMessage: CreateMessageBase {
    public init(
        extensionData: MessageExtensionsData,
        attachmentID: String? = nil,
        bundleID: String,
        expressiveSendStyleID: String? = nil,
        threadIdentifier: String? = nil,
        replyToGUID: String? = nil,
        replyToPart: Int? = nil,
        metadata: Message.Metadata?
    ) {
        self.extensionData = extensionData
        self.attachmentID = attachmentID
        self.bundleID = bundleID
        self.expressiveSendStyleID = expressiveSendStyleID
        self.threadIdentifier = threadIdentifier
        self.replyToGUID = replyToGUID
        self.replyToPart = replyToPart
        self.metadata = metadata

        let parseResult = ERAttributedString(forAttachment: attachmentID)

        let messageString = NSMutableAttributedString(attributedString: parseResult.string)
        messageString.append(.init(string: IMBreadcrumbCharacterString))
        messageString.addAttributes(
            [
                MessageAttributes.writingDirection: -1,
                MessageAttributes.breadcrumbOptions: 0,
                MessageAttributes.breadcrumbMarker: extensionData.layoutInfo?.caption ?? "Message Extension",
            ],
            range: messageString.range(of: IMBreadcrumbCharacterString)
        )

        self.bodyText = messageString as NSAttributedString
        self.transferGUIDs = parseResult.transferGUIDs

        var tempPayloadData = extensionData
        tempPayloadData.data  = tempPayloadData.data ?? tempPayloadData.synthesizedData
        self.payloadData = tempPayloadData.archive
        self.balloonBundleID = bundleID
    }

    public let extensionData: MessageExtensionsData
    public let attachmentID: String?
    public let bundleID: String
    public let expressiveSendStyleID: String?
    public let threadIdentifier: String?
    public let replyToPart: Int?
    public let replyToGUID: String?
    public let metadata: Message.Metadata?
    let balloonBundleID: String?
    let payloadData: Data?
    let bodyText: NSAttributedString
    let transferGUIDs: [String]

    public var attributedSubject: NSMutableAttributedString? {
        nil
    }

    var combinedFlags: IMMessageFlags {
        [.finished, .fromMe]
    }
}
