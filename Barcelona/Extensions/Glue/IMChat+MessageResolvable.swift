//
//  IMChat+MessageResolvable.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/7/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore

extension IMChat {
    /// Returns already-loaded chat, or queries for the chat if it is not loaded.
    public static func chat(forMessage guid: String) -> Promise<IMChat?, Error> {
        if let chat = resolve(withMessageGUID: guid) {
            return .success(chat)
        }
        
        return DBReader.shared.chatIdentifier(forMessageGUID: guid).map { chatIdentifier in
            guard let chatIdentifier = chatIdentifier else {
                return nil
            }
            
            return IMChat.resolve(withIdentifier: chatIdentifier)
        }
    }
}
