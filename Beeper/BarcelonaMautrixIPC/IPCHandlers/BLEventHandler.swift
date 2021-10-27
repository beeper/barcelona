//
//  BLEventBusDelegate.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import BarcelonaEvents
import IMCore

private extension ChatItemOwned {
    var mautrixFriendlyGUID: String {
        "\(chat.service!.rawValue);\(chat.imChat.isGroup ? "+" : "-");\(sender!)"
    }
    
    var chat: Chat {
        Chat.resolve(withIdentifier: chatID)!
    }
}

private extension CBMessageStatusChange {
    var mautrixFriendlyGUID: String? {
        guard let sender = sender else {
            return nil
        }
        
        return "\(message.service ?? "iMessage");\(chat.isGroup ? "+" : "-");\(sender)"
    }
}

public class BLEventHandler: CBPurgedAttachmentControllerDelegate {
    public static let shared = BLEventHandler()
    
    public let bus = EventBus()
    
    private let fifoQueue = FifoQueue<Void>()
    
    public func run() {
        let send: (IPCCommand) -> () = {
            BLWritePayload(.init(command: $0))
        }
        
        CBDaemonListener.shared.chatParticipantsPipeline.pipe { chat, participants in
            
        }
        
        CBDaemonListener.shared.unreadCountPipeline.pipe { chat, name in
            
        }
        
        CBDaemonListener.shared.chatNamePipeline.pipe { chat, name in
            
        }
        
        CBDaemonListener.shared.typingPipeline.pipe { chat, typing in
            send(.typing(.init(chat_guid: Chat.resolve(withIdentifier: chat)!.imChat.guid, typing: typing)))
        }
        
        CBDaemonListener.shared.messagePipeline.pipe { message in
            if message.fromMe, let lastSentMessageGUIDs = BLMetricStore.shared.get(typedValue: [String].self, forKey: .lastSentMessageGUIDs) {
                guard !lastSentMessageGUIDs.contains(message.id) else {
                    CLInfo("Mautrix", "Dropping last-sent message \(message.id)")
                    return
                }
            }
            
            if CBPurgedAttachmentController.shared.enabled {
                if message.fileTransferIDs.count > 0 {
                    CBPurgedAttachmentController.shared.process(transferIDs: message.fileTransferIDs).then {
                        send(.message(BLMessage(message: message.refresh())))
                    }
                    
                    return
                }
            }
            
            send(.message(BLMessage(message: message)))
        }
        
        CBDaemonListener.shared.messageStatusPipeline.pipe { change in
            switch change.type {
            case .read:
                send(.read_receipt(BLReadReceipt(sender_guid: change.mautrixFriendlyGUID, is_from_me: change.fromMe, chat_guid: change.chat.guid, read_up_to: change.messageID)))
            default:
                break
            }
        }

        bus.publisher.receiveEvent { event in
            switch event {
            case .contactUpdated(let contact):
                BLWritePayloads(contact.handles.flatMap { handle -> [BLContact?] in
                    switch handle.format {
                    case .phoneNumber:
                        return [contact.blContact(withGUID: "iMessage;-;\(handle.id)"), contact.blContact(withGUID: "SMS;-;\(handle.id)")]
                    default:
                        return [contact.blContact(withGUID: "iMessage;-;\(handle.id)")]
                    }
                }.compactMap { $0 }.map { .init(command: .contact($0)) })
            case .conversationUnreadCountChanged(let chat):
                CLInfo("Mautrix", "Read count for chat \(chat.id, privacy: .public): \(chat.unreadMessageCount, privacy: .public)")
            default:
                break
            }
        }
        
        bus.resume()
    }
    
    public func purgedTransferFailed(_ transfer: IMFileTransfer) {
        BLWritePayload(.init(id: nil, command: .error(.init(code: "file-transfer-failure", message: "Failed to download file transfer: \(transfer.errorDescription ?? transfer.error.description) (\(transfer.error.description))"))))
    }
}
