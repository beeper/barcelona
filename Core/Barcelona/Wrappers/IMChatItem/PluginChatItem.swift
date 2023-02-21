//
//  PluginChatItem.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/3/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import DigitalTouchShared
import Foundation
import IMCore
import LinkPresentation

public struct PluginChatItem: ChatItem, ChatItemAcknowledgable, Hashable {
    public static let ingestionClasses: [NSObject.Type] = [IMTranscriptPluginChatItem.self]

    public init(ingesting item: NSObject, context: IngestionContext) {
        self.init(item as! IMTranscriptPluginChatItem, chatID: context.chatID)
    }

    init(_ item: IMTranscriptPluginChatItem, chatID: String) {
        id = item.id
        self.chatID = chatID
        fromMe = item.isFromMe
        time = item.effectiveTime
        threadIdentifier = item.threadIdentifier
        threadOriginator = item.threadOriginatorID
        bundleID = item.balloonBundleID ?? "com.apple.messages.URLBalloonProvider"
        attachments = item.attachments

        var insertPayload: Bool = true

        switch bundleID {
        case "com.apple.DigitalTouchBalloonProvider":
            //            if let dataSource = item.dataSource, let messages = dataSource.perform(Selector(("createSessionMessages")))?.takeUnretainedValue() as? Array<ETMessage>, let message = messages.first {
            //                digitalTouch = DigitalTouchMessage(message: message)
            //            }
            insertPayload = false
            break
        case "com.apple.messages.URLBalloonProvider":
            if let dataSource = item.dataSource {
                richLink = dataSource.richLinkMetadata.map(RichLinkMetadata.init(metadata:))

                if let url = dataSource.url {
                    let urlString = url.absoluteString
                    self.fallback = TextChatItem(
                        item,
                        text: urlString,
                        parts: [.init(type: .link, string: urlString, data: .init(urlString), attributes: [])],
                        chatID: chatID
                    )
                } else if let text = item.text {
                    self.fallback = TextChatItem(
                        item,
                        text: text.string,
                        parts: [.init(type: .link, string: text.string, data: .init(text.string), attributes: [])],
                        chatID: chatID
                    )
                }

                insertPayload = false
            }
            break
        default:
            break
        }

        if bundleID.starts(with: "com.apple.messages.MSMessageExtensionBalloonPlugin"),
            let payloadData = item.dataSource?.payload
        {
            `extension` = MessageExtensionsData(payloadData)
            insertPayload = false
        }

        if insertPayload {
            payload = item.dataSource?.payload?.base64EncodedString()
        }
    }

    public var id: String
    public var chatID: String
    public var fromMe: Bool
    public var time: Double
    public var threadIdentifier: String?
    public var threadOriginator: String?
    public var digitalTouch: DigitalTouchMessage?
    public var richLink: RichLinkMetadata?
    public var fallback: TextChatItem?
    public var `extension`: MessageExtensionsData?
    public var payload: String?
    public var bundleID: String
    public var attachments: [Attachment]
    public var acknowledgments: [AcknowledgmentChatItem]?

    public var type: ChatItemType {
        .plugin
    }

    #if PRIVATE_LOGGING
    public var debugDescription: String {
        "\(type) { id=\(id) fromMe=\(fromMe) bundleID=\(bundleID) fallback=\(fallback?.text ?? "<none>") }"
    }
    #endif
}
