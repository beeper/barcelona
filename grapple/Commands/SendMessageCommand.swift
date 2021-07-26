//
//  SendMessageCommand.swift
//  grapple
//
//  Created by Eric Rabil on 7/26/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import SwiftCLI
import Barcelona

class SendMessageCommand: Command {
    let name = "send-message"
    
    @Param var chatID: String
    @Param var message: String
    
    func execute() throws {
        guard let chat = Chat.resolve(withIdentifier: chatID) else {
            fatalError("Unknown chat")
        }
        
        chat.send(message: CreateMessage(parts: [MessagePart(type: .text, details: message)])).whenSuccess { messages in
            print(messages)
            exit(0)
        }
    }
}
