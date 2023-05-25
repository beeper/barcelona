//
//  CBChat+MessageHandling.swift
//  Barcelona
//
//  Created by Eric Rabil on 8/8/22.
//

import Foundation
import IMSharedUtilities
import Logging

private let log = Logger(label: "CBChat")

extension Chat {
    public enum MessageInput: CustomDebugStringConvertible, CustomStringConvertible {
        case item(IMItem)
        case dict([AnyHashable: Any])

        public var guid: String? {
            switch self {
            case .item(let item): return item.id
            case .dict(let dict): return dict["guid"] as? String
            }
        }

        public func handle(message: CBMessage?, chat: Chat) throws -> CBMessage {
            var message = message
            switch self {
            case .item(let item):
                if message != nil {
                    try message!.handle(item: item, in: chat)
                    return message!
                }
                message = try CBMessage(item: item, chat: chat)
                return message!
            case .dict(let dict):
                if message != nil {
                    try message!.handle(dictionary: dict, in: chat)
                    return message!
                }
                message = try CBMessage(dictionary: dict, chat: chat)
                return message!
            }
        }

        private var shared: CustomDebugStringConvertible & CustomStringConvertible {
            switch self {
            case .dict(let dict as CustomDebugStringConvertible & CustomStringConvertible),
                .item(let dict as CustomDebugStringConvertible & CustomStringConvertible):
                return dict
            }
        }

        public var debugDescription: String {
            shared.debugDescription
        }

        public var description: String {
            shared.description
        }
    }

    @discardableResult public func handle(chat: Chat, input item: MessageInput) throws -> CBMessage? {
        guard let id = item.guid else {
            log.warning("dropping message \(item.debugDescription) as it has an invalid guid?!")
            return nil
        }
        let handledMessage = try item.handle(message: messages[id], chat: chat)
        messages[id] = handledMessage
        log.info("handled message \(id), \(handledMessage.debugDescription)")
        return handledMessage
    }

    @discardableResult public func handle(
        chat: Chat,
        item dictionary: [AnyHashable: Any]
    ) throws -> CBMessage? {
        try handle(chat: chat, input: .dict(dictionary))
    }
}

extension Chat {
    @discardableResult public func handle(chat: Chat, item: IMItem) throws -> CBMessage? {
        try handle(chat: chat, input: .item(item))
    }
}
