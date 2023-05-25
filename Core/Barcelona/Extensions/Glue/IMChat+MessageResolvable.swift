//
//  IMChat+MessageResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import BarcelonaDB
import Foundation
import IMCore

extension IMChat {
    public static func chat(
        withIdentifier chatId: String,
        onService service: IMServiceStyle
    ) -> IMChat? {
        return IMChatRegistry.shared._existingChat(
            withIdentifier: chatId,
            style: CBChatStyle.from(chatIdentifier: chatId).rawValue,
            service: service.service.name
        )
    }
}
