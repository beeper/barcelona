//
//  ChatResolvable.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 5/24/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation
import IMCore
import Logging

private let log = Logger(label: "ChatResolvable")

protocol ChatResolvable {
    var chat_guid: String { get set }
}

extension ChatResolvable {
    @MainActor
    var chat: IMChat? {
        get async {
            if let chat = IMChatRegistry.shared.existingChat(withGUID: chat_guid) {
                return chat
            } else {
                var parsed = ParsedGUID(rawValue: chat_guid)

                let service = parsed.service == "iMessage" ? IMServiceStyle.iMessage : .SMS
                let id = parsed.last

                if id.isPhoneNumber || id.isEmail || id.isBusinessID {
                    if let dmChat = await Chat.directMessage(withHandleID: id, service: service).imChat {
                        log.warning("No chat found for \(chat_guid) but using directMessage chat for \(id)")
                        return dmChat
                    }
                }
            }

            log.warning("No chat found for \(chat_guid)")
            return nil
        }
    }

    var service: IMServiceStyle {
        ParsedGUID(rawValue: chat_guid).service == "iMessage" ? IMServiceStyle.iMessage : .SMS
    }

    var cbChat: Chat? {
        get async {
            guard let chat = await chat else {
                return nil
            }

            return await Chat(chat)
        }
    }

    var blChat: BLChat? {
        get async {
            await chat?.blChat
        }
    }
}
