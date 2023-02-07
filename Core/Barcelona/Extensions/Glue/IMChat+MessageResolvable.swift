//
//  IMChat+MessageResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaDB
import IMCore

extension IMChat {
    /// Returns already-loaded chat, or queries for the chat if it is not loaded.
    public static func chat(forMessage guid: String, onService service: CBServiceName?) -> IMChat? {
        let chats: [IMChat] = {
            if #available(macOS 13.0, *) {
                return IMChatRegistry.shared._cachedChats(withMessageGUID: guid)
            } else {
                return IMChatRegistry.shared._chats(withMessageGUID: guid)
            }
        }()

        guard let service else {
            // If they can't provide us with a service (which unfortunately we need to support),
            // then just return the iMsg conversation if it exists, else return the first one
            return chats.first { $0.account.service == .iMessage() } ?? chats.first
        }

        return chats.first { $0.account.service == service.service }
    }

    public static func chat(withIdentifier chatId: String, onService service: IMServiceStyle, style: CBChatStyle?) -> IMChat? {
        let sharedRegistry = IMChatRegistry.shared

        guard let style else {
            // If we don't have a style, just iterate through all and grab the first one that works
            for style in CBChatStyle.allCases {
                if let chat = sharedRegistry._existingChat(withIdentifier: chatId, style: style.rawValue, service: service.service.name) {
                    return chat
                }
            }
            return nil
        }

        return sharedRegistry._existingChat(withIdentifier: chatId, style: style.rawValue, service: service.service.name)
    }
}
