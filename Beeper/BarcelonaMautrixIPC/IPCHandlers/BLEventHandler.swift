//
//  BLEventBusDelegate.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
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
    
    private let fifoQueue = FifoQueue<Void>()
    
    public func run() {
        let send: (IPCCommand) -> () = {
            BLWritePayload(.init(command: $0))
        }
        
        CBDaemonListener.shared.chatParticipantsPipeline.pipe { chat, participants in
            
        }
        
        CBDaemonListener.shared.unreadCountPipeline.pipe { chat, name in
            guard let chat = IMChat.resolve(withIdentifier: chat) else {
                return
            }
            
            if chat.unreadMessageCount == 0, let lastMessageID = chat.lastMessage?.id {
                CLInfo("Mautrix", "Read count for chat \(chat.id, privacy: .public): \(chat.unreadMessageCount, privacy: .public)")
                BLWritePayload(.init(id: nil, command: .read_receipt(.init(sender_guid: nil, is_from_me: true, chat_guid: chat.guid, read_up_to: lastMessageID))))
            }
        }
        
        CBDaemonListener.shared.chatNamePipeline.pipe { chat, name in
            
        }
        
        CBDaemonListener.shared.typingPipeline.pipe { chat, typing in
            send(.typing(.init(chat_guid: Chat.resolve(withIdentifier: chat)!.imChat.guid, typing: typing)))
        }
        
        CBDaemonListener.shared.messagePipeline.pipe { message in
            if message.fromMe, message.isSent || message.isUnsent, case .suppress(let payload) = SendMessageCommand.messageSent(withGUID: message.id) {
                if message.isSent {
                    payload.reply(withResponse: .message_receipt(message.partialMessage))
                } else {
                    let errorCode = message.refreshedErrorCode()
                    let errorMessage = errorCode.localizedDescription ?? "Your message couldn't be sent to iMessage."
                    payload.fail(code: errorCode.description, message: errorMessage)
                }
                CLInfo("Mautrix", "Dropping last-sent message \(message.id)")
                return
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
            
            if message.fromMe, message.isReadByMe, MXFeatureFlags.shared.enableReadHelpers {
                message.chat.messages(before: message.id, limit: 1, beforeDate: nil).first.then { message in
                    if let message = message {
                        send(.read_receipt(.init(sender_guid: nil, is_from_me: true, chat_guid: message.imChat.guid, read_up_to: message.id)))
                    }
                }
            }
        }
        
        CBDaemonListener.shared.messageStatusPipeline.pipe { change in
            switch change.type {
            case .read:
                send(.read_receipt(BLReadReceipt(sender_guid: change.mautrixFriendlyGUID, is_from_me: change.fromMe, chat_guid: change.chat.guid, read_up_to: change.messageID)))
            case .notDelivered:
                if case .suppress(let responsePayload) = SendMessageCommand.messageSent(withGUID: change.messageID) {
                    responsePayload.fail(code: "internal_error", message: "Sorry, we couldn't send your message.")
                }
            default:
                break
            }
        }
        
        NotificationCenter.default.addObserver(forName: .IMHandleInfoChanged, object: nil, queue: nil) { notification in
            if BMXContactListIsBuilding {
                return
            }
            
            guard let handle = notification.object as? IMHandle else {
                return
            }
            
            BLWritePayload(.init(command: .contact(BLContact.blContact(forHandleID: handle.id))))
        }
        
        NotificationCenter.default.addObserver(forName: .IMNicknameDidChange, object: nil, queue: nil) { notification in
            if BMXContactListIsBuilding {
                return
            }
            
            guard let dict = notification.object as? [AnyHashable: Any], let handleIDs = dict["handleIDs"] as? [String] else {
                return
            }
            
            BLWritePayloads(handleIDs.map(BLContact.blContact(forHandleID:)).map {
                .init(command: .contact($0))
            })
        }
    }
    
    public func purgedTransferFailed(_ transfer: IMFileTransfer) {
        BLWritePayload(.init(id: nil, command: .error(.init(code: "file-transfer-failure", message: "Failed to download file transfer: \(transfer.errorDescription ?? transfer.error.description) (\(transfer.error.description))"))))
    }
}

extension Chat {
    var lastMessageID: String? {
        imChat.lastMessage?.guid
    }
}
