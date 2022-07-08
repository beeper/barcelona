//
//  BLEventBusDelegate.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

@_spi(verboseLogging) import Barcelona
import IMCore

public class BLEventHandler: CBPurgedAttachmentControllerDelegate {
    public static let shared = BLEventHandler()
    
    private let fifoQueue = FifoQueue<Void>()
    
    @_spi(unitTestInternals) public func receiveTyping(_ chat: String, _ typing: Bool) {
        if let chat = IMChat.resolve(withIdentifier: chat), chat.isSingle, let recipientID = chat.recipient?.id, BLBlocklistController.shared.isSenderBlocked(recipientID) {
            return
        }
        
        guard let chat = Chat.resolve(withIdentifier: chat)?.imChat else {
            return
        }
        
        sendTyping(guid: chat.blChatGUID, typing: typing)
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
            sendChatMarkedRead(guid: chat.blChatGUID, upTo: lastMessageID)
        }
    }
    
    public func run() {
        CBDaemonListener.shared.unreadCountPipeline.pipe(unreadCountChanged)
        CBDaemonListener.shared.typingPipeline.pipe(receiveTyping)
        
        CBDaemonListener.shared.messageStatusPipeline.pipe(handleMessageStatus(_:))
        BLMessageExpert.shared.eventPipeline.pipe(handleMessageEvent(_:))
        
        NotificationCenter.default.addObserver(forName: .IMHandleInfoChanged, object: nil, queue: nil, using: handleInfoChanged(notification:))
        NotificationCenter.default.addObserver(forName: .IMNicknameDidChange, object: nil, queue: nil, using: nicknameChanged(notification:))
    }
    
    func handleMessageStatus(_ change: CBMessageStatusChange) {
        guard change.type == .read else {
            return
        }
        if let sender = change.sender, BLBlocklistController.shared.isSenderBlocked(sender) {
            return
        }
        sendReadReceipt(change: change)
    }
    
    func handleMessageEvent(_ event: BLMessageExpert.BLMessageEvent) {
        switch event {
        case .message(let message):
            if let senderID = message.senderID, BLBlocklistController.shared.isSenderBlocked(senderID) {
                return
            }
            if CBPurgedAttachmentController.shared.enabled {
                if message.fileTransferIDs.count > 0 {
                    CBPurgedAttachmentController.shared.process(transferIDs: message.fileTransferIDs).then { [message] in
                        sendMessageEvent(message.refresh())
                    }
                    return
                }
            }
            sendMessageEvent(message)
        case .sent(id: let id, service: let service, chat: let chat, time: _):
            sendMessageSent(withGUID: id, service: service, chatGUID: chat.blChatGUID)
        case .failed(id: let id, service: let service, chat: let chat, code: let code):
            sendMessageFailed(withGUID: id, code: code, service: service, chatGUID: chat.blChatGUID)
        default:
            break
        }
    }
    
    func handleInfoChanged(notification: Notification) {
        if BMXContactListIsBuilding {
            return
        }
        
        *CLDebug("BLEventHandler", "Received IMHandleInfoChanged notification")
        
        guard let handle = notification.object as? IMHandle else {
            return
        }
        
        sendUpdatedContact(for: handle)
    }
    
    func nicknameChanged(notification: Notification) {
        if BMXContactListIsBuilding {
            return
        }
        
        *CLDebug("BLEventHandler", "Received IMNicknameDidChange notification")
        
        guard let dict = notification.object as? [AnyHashable: Any], let handleIDs = dict["handleIDs"] as? [String] else {
            return
        }
        
        handleIDs.forEach(sendUpdatedContact(forHandleID:))
    }
    
    public func purgedTransferFailed(_ transfer: IMFileTransfer) {
        sendError(code: "file-transfer-failure", message: "Failed to download file transfer: \(transfer.errorDescription ?? transfer.error.description) (\(transfer.error.description))")
    }
}

extension Chat {
    var lastMessageID: String? {
        imChat.lastMessage?.guid
    }
}
