//
//  IMChat+Resolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/11/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChat: Resolvable, _ConcreteBasicResolvable {
    public static func resolve(withIdentifiers identifiers: [String]) -> [IMChat] {
        identifiers.compactMap { identifier in
            if BLIsSimulation {
                guard let chat = IMChatRegistry.shared.allChats.first(where: { $0.chatIdentifier == identifier }) else {
                    return nil
                }
                
                return chat
            } else {
                guard let chat = IMChatRegistry.shared.existingChat(withChatIdentifier: identifier) else {
                    return nil
                }
                
                return chat
            }
        }
    }
    
    public static func resolve(withMessageGUID guid: String) -> IMChat? {
        IMChatRegistry.shared._chats(withMessageGUID: guid).first
    }
}
