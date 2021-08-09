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

private extension HealthChecker.AuthenticationState {
    var abnormalState: BridgeState? {
        switch self {
        case .authenticated:
            return nil
        case .none:
            return .unconfigured
        case .registrationFailure:
            return .badCredentials
        case .validationFaliure:
            return .unknownError
        case .signedOut:
            return .loggedOut
        }
    }
}

private extension HealthChecker.ConnectionState {
    var abnormalState: BridgeState? {
        switch self {
        case .connected:
            return nil
        case .errored:
            return .unknownError
        case .offline:
            return .transientDisconnect
        case .transientDisconnect:
            return .transientDisconnect
        }
    }
}

private extension HealthState {
    var statusCommand: BridgeStatusCommand {
        BridgeStatusCommand(
            state_event: authenticationState.abnormalState ?? connectionState.abnormalState ?? .connected,
            error: authenticationState.error ?? connectionState.error,
            message: authenticationState.message ?? connectionState.message,
            remote_id: nil,
            remote_name: nil
        )
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
                        
                        CLInfo("Mautrix", "typing: %@", String(data: try! JSONEncoder().encode(message), encoding: .utf8)!)
                        send(.typing(.init(chat_guid: message.imChat.guid, typing: !message.isCancelTypingMessage)))
                        return
                    }
                    
                    if message.fromMe, let lastSentMessageGUIDs = BLMetricStore.shared.get(typedValue: [String].self, forKey: .lastSentMessageGUIDs) {
                        guard !lastSentMessageGUIDs.contains(message.id) else {
                            return
                        }
                    }
                    
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
            case .healthChanged(let state):
                send(.bridge_status(state.statusCommand))
            default:
                break
            }
        }
        
        bus.resume()
    }
}
