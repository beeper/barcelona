//
//  BLEventBusDelegate.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaEvents

public class BLEventHandler {
    public static let shared = BLEventHandler()
    
    let bus = EventBus()
    
    public func run() {
        let send: (IPCCommand) -> () = {
            BLWritePayload(.init(command: $0))
        }

        bus.messageStream.filter {
            $0.isTypingMessage && !$0.fromMe
        }.receiveForever { typingMessage in
            BLInfo("typing: %@", String(data: try! JSONEncoder().encode(typingMessage), encoding: .utf8)!)
            
            send(.typing(.init(chat_guid: typingMessage.imChat.guid, typing: !typingMessage.isCancelTypingMessage)))
        }
        
//         MARK: - message handler
        bus.messageStream.filter {
            !$0.isTypingMessage && !$0.fromMe
        }.map {
            BLMessage(message: $0)
        }.receiveForever { message in
            send(.message(message))
        }
        
        bus.resume()
    }
}
