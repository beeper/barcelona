//
//  BLEventBusDelegate.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaEvents

private extension ChatItemOwned {
    var mautrixFriendlyGUID: String {
        "\(chat.service!.rawValue);\(chat.imChat.isGroup ? "+" : "-");\(sender!)"
    }
    
    var chat: Chat {
        Chat.resolve(withIdentifier: chatID)!
    }
}

public class BLEventHandler {
    public static let shared = BLEventHandler()
    
    let bus = EventBus()
    
    public func run() {
        let send: (IPCCommand) -> () = {
            BLWritePayload(.init(command: $0))
        }

        bus.publisher.receiveEvent { event in
            switch event {
            case .itemsReceived(let items):
                items.compactMap { $0.item as? Message }.forEach { message in
                    if message.isTypingMessage {
                        guard !message.fromMe else {
                            return
                        }
                        
                        BLInfo("typing: %@", String(data: try! JSONEncoder().encode(message), encoding: .utf8)!)
                        send(.typing(.init(chat_guid: message.imChat.guid, typing: !message.isCancelTypingMessage)))
                        return
                    }
                    
                    if message.fromMe {
                        guard let lastSentMessageGUIDs = BLMetricStore.shared.get(typedValue: [String].self, forKey: .lastSentMessageGUIDs), !lastSentMessageGUIDs.contains(message.id) else {
                            return
                        }
                    }
                    
                    BLInfo("received message: %@", String(data: try! JSONEncoder().encode(message), encoding: .utf8)!)
                    send(.message(BLMessage(message: message)))
                }
                
                break
            case .itemStatusChanged(let item):
                switch item.statusType {
                case .read:
                    send(.read_receipt(BLReadReceipt(sender_guid: item.mautrixFriendlyGUID, is_from_me: item.fromMe, chat_guid: Chat.resolve(withIdentifier: item.chatID)!.imChat.guid, read_up_to: item.itemID)))
                default:
                    break
                }
            default:
                break
            }
        }
        
        bus.resume()
    }
}
