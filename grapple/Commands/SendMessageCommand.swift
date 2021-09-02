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

func createDM(toHandle handle: String) -> Chat {
    let handle = Registry.sharedInstance.imHandle(withID: handle)!
    
    let chat = IMChat()!._init(withGUID: NSString.stringGUID(), account: handle.account, style: ChatStyle.single.rawValue, roomName: nil, displayName: nil, lastAddressedHandle: nil, lastAddressedSIMID: nil, items: nil, participants: [handle], isFiltered: true, hasHadSuccessfulQuery: true)!
    
    chat._setupObservation()
    
    IMChatRegistry.shared._registerChat(chat, isIncoming: false, guid: chat.guid)
    
    return Chat(chat)
}

class SendMessageCommand: Command {
    let name = "send-message"
    
    @Param var chatID: String
    @Param var message: String
    
    func execute() throws {
        let chat = Chat.resolve(withIdentifier: chatID) ?? createDM(toHandle: chatID)
        
        print(try chat.send(message: CreateMessage(parts: [MessagePart(type: .text, details: message)])))
        exit(0)
    }
}
