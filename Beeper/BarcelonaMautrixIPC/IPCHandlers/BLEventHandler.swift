//
//  BLEventHandler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import Barcelona
import IMCore
import IDS
import Swog
import Contacts

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

private extension BLContact {
    static func emptyContact(for handleID: String) -> BLContact {
        if handleID.isEmail {
            // return BLContact(phones: [], emails: [handleID], user_guid: "iMessage;-;\(handleID)")
            return BLContact.with { $0.emails = [handleID]; $0.userGuid = .iMessageDM(handleID) }
        } else if handleID.isPhoneNumber {
            // return BLContact(phones: [handleID], emails: [], user_guid: "iMessage;-;\(handleID)")
            return BLContact.with { $0.phones = [handleID]; $0.userGuid = .iMessageDM(handleID) }
        } else {
            // return BLContact(phones: [], emails: [], user_guid: "iMessage;-;\(handleID)")
            return BLContact.with { $0.userGuid = .iMessageDM(handleID) }
        }
    }
}

extension PBGUID {
    static func iMessageDM(_ localID: String) -> PBGUID {
        .with {
            $0.service = "iMessage"
            $0.localID = localID
        }
    }
}

import BarcelonaMautrixIPCProtobuf

extension CBChat {
    var bestChatIdentifier: PBGUID! {
        chatForSending().map { chat in
            PBGUID.with { guid in
                guid.service = chat.account.serviceName
                guid.isGroup = chat.isGroup
                guid.localID = chat.chatIdentifier
            }
        }
    }
}

public class BLEventHandler: CBPurgedAttachmentControllerDelegate {
    public static let shared = BLEventHandler()
    
    private let fifoQueue = FifoQueue<Void>()
    
    @_spi(unitTestInternals) public func receiveTyping(_ chat: CBChat, _ typing: Bool) {
        if chat.style == .instantMessage, let recipientID = chat.mergedRecipientIDs.first, BLBlocklistController.shared.isSenderBlocked(recipientID) {
            return
        }
        
        // send(.typing(.init(chat_guid: Chat.resolve(withIdentifier: chat)!.imChat.blChatGUID, typing: typing)))
        BLWritePayload {
            $0.command = .typingNotification(.with {
                $0.chatGuid = .with {
                    $0.service = chat.serviceForSending.name
                    $0.isGroup = chat.style == .group
                    // $0.localID = chat.
                }
            })
        }
    }
    
    @_spi(unitTestInternals) public func unreadCountChanged(_ chat: CBChat, _ count: Int) {
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
            BLWritePayload {
                $0.command = .readReceipt(.with { rr in
                    change.sender.map { senderID in
                        rr.senderGuid = .with {
                            $0.service = change.service
                            $0.isGroup = change.chat.isGroup
                            $0.localID = senderID
                        }
                    }
                    rr.isFromMe = change.fromMe
                    rr.chatGuid = .with {
                        $0.service = change.service
                        $0.isGroup = change.chat.isGroup
                        $0.localID = change.chatID
                    }
                    rr.readUpTo = change.messageID
                    rr.correlations = .with { correlations in
                        change.chat.correlationIdentifier.oassign(to: &correlations.chat)
                        change.senderCorrelationID.oassign(to: &correlations.sender)
                    }
                })
            }
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
                            BLWritePayload {
                                $0.command = .message(PBMessage(message: message.refresh()))
                            }
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
                BLWritePayload {
                    $0.command = .message(PBMessage(message: message))
                }
                // BLWritePayload {}
            case .sent(id: let id, service: let service, chat: let chat, time: _, senderCorrelationID: let senderCorrelationID):
                BLWritePayload {
                    $0.command = .sendMessageStatus(.with { status in
                        status.guid = id
                        status.service = service
                        status.status = "sent"
                        status.chatGuid = .with {
                            $0.service = service
                            $0.isGroup = chat.isGroup
                            $0.localID = chat.chatIdentifier
                        }
                        status.correlations = .with {
                            chat.correlationIdentifier.oassign(to: &$0.chat)
                            senderCorrelationID.oassign(to: &$0.sender)
                        }
                    })
                }
            case .failed(id: let id, service: let service, chat: let chat, code: let code, senderCorrelationID: let senderCorrelationID):
                BLWritePayload {
                    $0.command = .sendMessageStatus(.with { status in
                        status.guid = id
                        status.service = service
                        status.status = "failed"
                        status.chatGuid = .with {
                            $0.service = service
                            $0.isGroup = chat.isGroup
                            $0.localID = chat.chatIdentifier
                        }
                        status.correlations = .with {
                            chat.correlationIdentifier.oassign(to: &$0.chat)
                            senderCorrelationID.oassign(to: &$0.sender)
                        }
                        status.error = .with { error in
                            error.code = code.description
                            code.localizedDescription.oassign(to: &error.message)
                        }
                    })
                }
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
            BLWritePayload {
                $0.command = .contact(blContact)
            }
        }
        
        NotificationCenter.default.addObserver(forName: "IMCSChangeHistoryUpdateContactEventNotification", object: nil, queue: nil, using: handleAddOrChangeContactNotification(_:))
        NotificationCenter.default.addObserver(forName: "IMCSChangeHistoryAddContactEventNotification", object: nil, queue: nil, using: handleAddOrChangeContactNotification(_:))
        
        // There's no way Apple-native way to know which handle IDs are being cleared out, without avoiding false positives.
        CBDaemonListener.shared.resetHandlePipeline.pipe { handleIDs in
            BLWritePayloads(handleIDs.map(BLContact.emptyContact(for:)).map { contact in .with { $0.command = .contact(contact) } })
        }
        
        var nicknamesLoadedAt: Date? = nil, lastNicknamePayloads: [String: BLContact] = [:]
        NotificationCenter.default.addObserver(forName: .IMNicknameControllerDidLoad, object: nil, queue: nil) { notification in
            nicknamesLoadedAt = Date()
        }
        
        NotificationCenter.default.addObserver(forName: .IMNicknameDidChange, object: nil, queue: nil) { notification in
            guard let dict = notification.object as? [AnyHashable: Any], let handleIDs = dict["handleIDs"] as? [String] else {
                return
            }
            
            let payloads: [PBPayload] = handleIDs.map { BLContact.blContact(forHandleID: $0, assertCorrelationID: false) }.filter { contact in
                let rawValue = contact.userGuid.rawValue
                if lastNicknamePayloads[rawValue] == contact {
                    return false
                }
                lastNicknamePayloads[rawValue] = contact
                return true
            }.map { contact in
                .with {
                    $0.command = .contact(contact)
                }
            }
            
            guard let nicknamesLoadedAt = nicknamesLoadedAt, nicknamesLoadedAt.distance(to: Date()) > 1 else {
                return
            }
            
            if payloads.isEmpty {
                return
            }
            
            BLWritePayloads(payloads)
        }
    }
    
    public func purgedTransferResolved(_ transfer: IMFileTransfer) {
        
    }
    
    public func purgedTransferFailed(_ transfer: IMFileTransfer) {
        BLWritePayload {
            $0.command = .error(.with {
                $0.code = "file-transfer-failure"
                $0.message = "Failed to download file transfer: \(transfer.errorDescription ?? transfer.error.description) (\(transfer.error.description))"
            })
        }
    }
}

extension Chat {
    var lastMessageID: String? {
        imChat.lastMessage?.guid
    }
}

extension PBGUID {
    var rawValue: String {
        "\(service);\(isGroup ? "+" : "-");\(localID)"
    }
}
