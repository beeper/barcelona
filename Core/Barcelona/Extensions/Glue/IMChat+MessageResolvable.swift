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
        onService service: IMServiceStyle,
        style: CBChatStyle?
    ) -> IMChat? {
        let sharedRegistry = IMChatRegistry.shared

        guard let style else {
            // If we don't have a style, just iterate through all and grab the first one that works
            for style in CBChatStyle.allCases {
                if let chat = sharedRegistry._existingChat(
                    withIdentifier: chatId,
                    style: style.rawValue,
                    service: service.service.name
                ) {
                    return chat
                }
            }
            return nil
        }

        return sharedRegistry._existingChat(
            withIdentifier: chatId,
            style: style.rawValue,
            service: service.service.name
        )
    }
}
