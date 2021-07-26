//
//  BLEventBusDelegate.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import BarcelonaEvents
import Combine

public class BLEventHandler {
    public static let shared = BLEventHandler()
    
    let bus = EventBus()
    private var cancellables = Set<AnyCancellable>()
    
    public func run() {
        let send: (IPCCommand) -> () = {
            BLWritePayload(.init(command: $0))
        }
        
//         MARK: - typing handler
        bus.messageStream.filter {
            $0.isTypingMessage
        }.sink {
            guard let chatGUID = $0.imChat?.guid, $0.fromMe != true else {
                return
            }
            
            BLInfo("typing: %@", String(data: try! JSONEncoder().encode($0), encoding: .utf8)!)
            
            send(.typing(.init(chat_guid: chatGUID, typing: !$0.isCancelTypingMessage)))
        }.store(in: &cancellables)
        
//         MARK: - message handler
        bus.messageStream.filter {
            !$0.isTypingMessage
        }.map {
            BLMessage(message: $0)
        }.sink { message in
            send(.message(message))
        }.store(in: &cancellables)
        
//        let _ = EventBus.shared.itemStatusStream.sink { status in
//            send(.read_receipt(.init(sender_guid: status., is_from_me: <#T##Bool#>, chat_guid: <#T##String#>, read_up_to: <#T##String#>)))
//        }
        bus.resume()
    }
}
