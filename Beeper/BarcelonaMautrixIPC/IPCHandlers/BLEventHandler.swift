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
import Swog

fileprivate let log = Logger(category: "self.ipcChannel.writePayload")

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
    private let fifoQueue = FifoQueue<Void>()
    
    private let ipcChannel: MautrixIPCChannel
    
    public init(ipcChannel: MautrixIPCChannel) {
        self.ipcChannel = ipcChannel
    }
    
    internal func send(_ command: IPCCommand) {
        ipcChannel.writePayload(.init(command: command))
    }
    
    @_spi(unitTestInternals) public func receiveTyping(_ chat: String, _ typing: Bool) {
        if let chat = IMChat.resolve(withIdentifier: chat), chat.isSingle, let recipientID = chat.recipient?.id, BLBlocklistController.shared.isSenderBlocked(recipientID) {
            return
        }
        
        send(.typing(.init(chat_guid: Chat.resolve(withIdentifier: chat)!.imChat.blChatGUID, typing: typing)))
    }
    
    @_spi(unitTestInternals) public func unreadCountChanged(_ chat: String, _ count: Int) {
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

            log.debug("Processing read receipt from \(String(describing: change.mautrixFriendlyGUID)) in \(change.chat.blChatGUID) for \(change.messageID)")

            self.ipcChannel.writePayload(.init(command: .read_receipt(BLReadReceipt(sender_guid: change.mautrixFriendlyGUID, is_from_me: change.fromMe, chat_guid: change.chat.blChatGUID, read_up_to: change.messageID, correlation_id: change.chat.correlationIdentifier, sender_correlation_id: change.senderCorrelationID))))
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
                            self.ipcChannel.writePayload(.init(command: .message(BLMessage(message: message.refresh()))))
                        }
                        return
                    }
                }
                #if DEBUG
                if NSUserName() == "ericrabil" || NSUserName() == "3AFBF1C7-8088-4ACF-B998-BC84C6947233" {
                    let message = BLLoadIMMessage(withGUID: message.id)
                    CLDebug("", "%@", message.debugDescription)
                }
                #endif
                let blMessage = BLMessage(message: message)
                log.debug("Sending message payload \(blMessage.guid) \(blMessage.chat_guid) \(blMessage.sender_guid ?? "nil") \(blMessage.sender_correlation_id ?? "nil") \(blMessage.service)")
                self.ipcChannel.writePayload(.init(command: .message(blMessage)))
            case .sent(id: let id, service: let service, chat: let chat, time: _, senderCorrelationID: let senderCorrelationID):
                self.ipcChannel.writePayload(.init(command: .send_message_status(BLMessageStatus(sentMessageGUID: id, onService: service, forChatGUID: chat.blChatGUID, correlation_id: chat.correlationIdentifier, sender_correlation_id: senderCorrelationID))))
            case .failed(id: let id, service: let service, chat: let chat, code: let code, senderCorrelationID: let senderCorrelationID):
                self.ipcChannel.writePayload(.init(command: .send_message_status(BLMessageStatus(guid: id, chatGUID: chat.blChatGUID, status: .failed, service: service, message: code.localizedDescription, statusCode: code.description, correlation_id: chat.correlationIdentifier, sender_correlation_id: senderCorrelationID))))
            default:
                break
            }
        }
    }
    
    public func purgedTransferFailed(_ transfer: IMFileTransfer) {
        self.ipcChannel.writePayload(.init(id: nil, command: .error(.init(code: "file-transfer-failure", message: "Failed to download file transfer: \(transfer.errorDescription ?? transfer.error.description) (\(transfer.error.description))"))))
    }
}

extension Chat {
    var lastMessageID: String? {
        imChat.lastMessage?.guid
    }
}
