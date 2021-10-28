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
import IMCore

class SendMessageCommand: BarcelonaCommand {
    let name = "send-message"
    let shortDescription = "send a textual message to a chat with either a comma-delimited set of recipients or a chat identifier"
    
    @Param var destination: String
    @Param var message: String
    
    @Flag("-i", "--id", description: "treat the destination as a chat ID")
    var isID: Bool
    
    var chat: Chat {
        if isID {
            guard let chat = Chat.resolve(withIdentifier: destination) else {
                fatalError("Unknown chat with identifier \(destination)")
            }
            
            return chat
        }
        
        return Chat.chat(withHandleIDs: destination.split(separator: ",").map(String.init))
    }
    
    func execute() throws {
        IMChatRegistry.shared._postMessageSentNotifications = true
        
        var message: Message! = nil
        
        NotificationCenter.default.addObserver(forName: .IMChatRegistryMessageSent, object: nil, queue: nil) { notification in
            guard let sentMessage = notification.userInfo?["__kIMChatRegistryMessageSentMessageKey"] as? IMMessage else {
                return
            }
            
            guard message?.id == sentMessage.id else {
                return
            }
            
            print(sentMessage.debugDescription)
            
            exit(0)
        }
        
        message = try chat.send(message: CreateMessage(parts: [MessagePart(type: .text, details: self.message)]))
    }
}