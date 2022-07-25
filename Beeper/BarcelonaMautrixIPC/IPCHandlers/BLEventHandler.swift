//
//  BLEventHandler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import IMCore
import IDS

private extension ChatItemOwned {
    var mautrixFriendlyGUID: String {
        "\(chat.service!.rawValue);\(chat.imChat.isGroup ? "+" : "-");\(sender!)"
    }
    
    var chat: Chat {
        Chat.resolve(withIdentifier: chatID)!
    }
}

private extension CBMessageStatusChange {
    var senderHandle: IMHandle? {
        guard let service = IMServiceAgent.shared().service(withName: service) else {
            return nil
        }
        guard let account = IMAccountController.shared.bestAccount(forService: service) else {
            return nil
        }
        guard let sender = sender else {
            return nil
        }
        return account.imHandle(withID: sender)
    }
    
    var mautrixFriendlyGUID: String? {
        guard let sender = sender else {
            return nil
        }
        return "\(message.service ?? "iMessage");\(chat.isGroup ? "+" : "-");\(sender)"
    }
}

extension IMChatRegistry {
    func existingChat(forHandleID handleID: String) -> IMChat? {
        for account in IMAccountController.shared.accounts {
            let handle = account.imHandle(withID: handleID)
            if let chat = existingChat(for: handle) {
                return chat
            }
        }
        return nil
    }
}

public class BLEventHandler: CBPurgedAttachmentControllerDelegate {
    public static let shared = BLEventHandler()
    
    private let fifoQueue = FifoQueue<Void>()
    
    internal func send(_ command: IPCCommand) {
        BLWritePayload(.init(command: command))
    }
    
    @_spi(unitTestInternals) public func receiveTyping(_ chat: String, _ typing: Bool) {
        if let chat = IMChat.resolve(withIdentifier: chat), chat.isSingle, let recipientID = chat.recipient?.id, BLBlocklistController.shared.isSenderBlocked(recipientID) {
            return
        }
        
        send(.typing(.init(chat_guid: Chat.resolve(withIdentifier: chat)!.imChat.blChatGUID, typing: typing)))
    }
    
    @_spi(unitTestInternals) public func unreadCountChanged(_ chat: String, _ count: Int) {
        guard let chat = IMChat.resolve(withIdentifier: chat) else {
            return
        }
        
        if chat.isSingle, let recipientID = chat.recipient?.id, BLBlocklistController.shared.isSenderBlocked(recipientID) {
            return
        }
        
        if chat.unreadMessageCount == 0, let lastMessageID = chat.lastMessage?.id {
            CLInfo("Mautrix", "Read count for chat \(chat.id, privacy: .public): \(chat.unreadMessageCount, privacy: .public)")
            BLWritePayload(.init(id: nil, command: .read_receipt(.init(sender_guid: nil, is_from_me: true, chat_guid: chat.blChatGUID, read_up_to: lastMessageID, correlation_id: chat.senderCorrelationID))))
        }
    }
    
    public func run() {
        CBDaemonListener.shared.unreadCountPipeline.pipe(unreadCountChanged)
        CBDaemonListener.shared.typingPipeline.pipe(receiveTyping)
        
        CBDaemonListener.shared.messageStatusPipeline.pipe { change in
            guard change.type == .read else {
                return
            }
            if let sender = change.sender, BLBlocklistController.shared.isSenderBlocked(sender) {
                return
            }
            BLWritePayload(.init(command: .read_receipt(BLReadReceipt(sender_guid: change.mautrixFriendlyGUID, is_from_me: change.fromMe, chat_guid: change.chat.blChatGUID, read_up_to: change.messageID, correlation_id: change.chat.senderCorrelationID, sender_correlation_id: change.senderCorrelationID))))
        }
        
        BLMessageExpert.shared.eventPipeline.pipe { event in
            switch event {
            case .message(let message):
                if let senderID = message.senderID, BLBlocklistController.shared.isSenderBlocked(senderID) {
                    return
                }
                if CBPurgedAttachmentController.shared.enabled {
                    if message.fileTransferIDs.count > 0 {
                        CBPurgedAttachmentController.shared.process(transferIDs: message.fileTransferIDs).then { [message] in
                            BLWritePayload(.init(command: .message(BLMessage(message: message.refresh()))))
                        }
                        return
                    }
                }
                BLWritePayload(.init(command: .message(BLMessage(message: message))))
            case .sent(id: let id, service: let service, chat: let chat, time: _):
                BLWritePayload(.init(command: .send_message_status(BLMessageStatus(sentMessageGUID: id, onService: service, forChatGUID: chat.blChatGUID, correlation_id: chat.senderCorrelationID))))
            case .failed(id: let id, service: let service, chat: let chat, code: let code):
                BLWritePayload(.init(command: .send_message_status(BLMessageStatus(guid: id, chatGUID: chat.blChatGUID, status: .failed, service: service, message: code.localizedDescription, statusCode: code.description, correlation_id: chat.senderCorrelationID))))
            default:
                break
            }
        }
        
        func handleAddOrChangeContactNotification(_ notification: Notification) {
            guard let contact = notification.userInfo?["__kIMCSChangeHistoryContactKey"] as? CNContact else {
                return
            }
            guard let blContact = BLContact.blContact(for: contact) else {
                return
            }
            BLWritePayload(.init(command: .contact(blContact)))
        }
        
        NotificationCenter.default.addObserver(forName: "IMCSChangeHistoryUpdateContactEventNotification", object: nil, queue: nil, using: handleAddOrChangeContactNotification(_:))
        NotificationCenter.default.addObserver(forName: "IMCSChangeHistoryAddContactEventNotification", object: nil, queue: nil, using: handleAddOrChangeContactNotification(_:))
        
        // There's no way Apple-native way to know which handle IDs are being cleared out, without avoiding false positives.
        CBDaemonListener.shared.resetHandlePipeline.pipe { handleIDs in
            for handleID in handleIDs {
                BLWritePayload(.init(command: .contact(.emptyContact(for: handleID))))
            }
            BLWritePayloads(handleIDs.map(BLContact.emptyContact(for:)).map { IPCPayload(command: .contact($0)) })
        }
        
        var nicknamesLoaded = false
        NotificationCenter.default.addObserver(forName: .IMNicknameControllerDidLoad, object: nil, queue: nil) { notification in
            nicknamesLoaded = true
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
