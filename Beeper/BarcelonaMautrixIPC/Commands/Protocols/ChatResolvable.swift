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
            return await getIMChatForChatGuid(chat_guid)
        }
    }

    var service: IMServiceStyle {
        getIMServiceStyleForChatGuid(chat_guid)
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
