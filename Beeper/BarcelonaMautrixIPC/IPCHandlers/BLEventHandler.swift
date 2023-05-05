//
//  BLEventHandler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 6/14/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Combine
import IDS
import IMCore
import Logging

private let log = Logger(label: "self.ipcChannel.writePayload")

extension CBMessageStatusChange {
    fileprivate var mautrixFriendlyGUID: String? {
        guard let sender = sender else {
            return nil
        }
        return "\(service.rawValue);\(chat?.isGroup ?? false ? "+" : "-");\(sender)"
    }
}

public class BLEventHandler: CBPurgedAttachmentControllerDelegate {

    private let ipcChannel: MautrixIPCChannel
    private var bag = Set<AnyCancellable>()

    public init(ipcChannel: MautrixIPCChannel) {
        self.ipcChannel = ipcChannel
    }

    internal func send(_ command: IPCCommand) {
        ipcChannel.writePayload(.init(command: command))
    }

    public func receiveTyping(_ chat: String, service: IMServiceStyle, _ typing: Bool) {
        guard let chat = IMChat.chat(withIdentifier: chat, onService: service, style: nil) else {
            return
        }

        if chat.isSingle,
            let recipientID = chat.recipient?.id,
            BLBlocklistController.shared.isSenderBlocked(recipientID)
        {
            return
        }

        send(.typing(.init(chat_guid: chat.blChatGUID, typing: typing)))
    }

    public func run() {
        CBDaemonListener.shared.typingPipeline.sink(receiveValue: receiveTyping).store(in: &bag)

        CBDaemonListener.shared.messageStatusPipeline
            .sink { change in
                guard change.type == .read else {
                    return
                }

                if let sender = change.sender, BLBlocklistController.shared.isSenderBlocked(sender) {
                    return
                }

                guard let chat = change.chat else {
                    log.error("change \(change.chatID), \(change.messageID) can't resolve its IMChat; can't process")
                    return
                }

                log.debug(
                    "Processing read receipt from \(String(describing: change.mautrixFriendlyGUID)) in \(chat.blChatGUID) for \(change.messageID)"
                )

                self.ipcChannel.writePayload(
                    .init(
                        command: .read_receipt(
                            BLReadReceipt(
                                sender_guid: change.mautrixFriendlyGUID,
                                is_from_me: change.fromMe,
                                chat_guid: chat.blChatGUID,
                                read_up_to: change.messageID
                            )
                        )
                    )
                )
            }
            .store(in: &bag)

        BLMessageExpert.shared.eventPipeline
            .sink { [unowned self] event -> Void in
                Task {
                    switch event {
                    case .message(let message):
                        if let senderID = message.senderID, BLBlocklistController.shared.isSenderBlocked(senderID) {
                            return
                        }
                        if CBPurgedAttachmentController.shared.enabled {
                            if message.fileTransferIDs.count > 0 {
                                log.debug("Message \(message.id) has attachments, processing")
                                await CBPurgedAttachmentController.shared.process(transferIDs: message.fileTransferIDs)
                                log.debug("Processed attachments for \(message.id)")
                                ipcChannel.writePayload(
                                    .init(command: .message(BLMessage(message: message.refresh())))
                                )
                                return
                            }
                        }
                        let blMessage = BLMessage(message: message)
                        log.debug(
                            "Sending message payload \(blMessage.guid) \(blMessage.chat_guid) \(blMessage.sender_guid ?? "nil") \(blMessage.service)"
                        )
                        self.ipcChannel.writePayload(.init(command: .message(blMessage)))
                    case .sent(let id, let service, let chat, time: _):
                        guard let chat else {
                            log.error(
                                ".sent event \(event.id), \(event.service) can't resolve its IMChat; can't pass to mautrix."
                            )
                            return
                        }

                        self.ipcChannel.writePayload(
                            .init(
                                command: .send_message_status(
                                    BLMessageStatus(
                                        sentMessageGUID: id,
                                        onService: service.rawValue,
                                        forChatGUID: chat.blChatGUID
                                    )
                                )
                            )
                        )
                    case .failed(let id, let service, let chat, let code):
                        guard let chat else {
                            log.error(".failed event \(id), \(service) has no IMChat; can't pass to mautrix.")
                            return
                        }

                        self.ipcChannel.writePayload(
                            .init(
                                command: .send_message_status(
                                    BLMessageStatus(
                                        guid: id,
                                        chatGUID: chat.blChatGUID,
                                        status: .failed,
                                        service: service.rawValue,
                                        message: code.localizedDescription,
                                        statusCode: code.description
                                    )
                                )
                            )
                        )
                    case .delivered(let id, let service, let chat, _):
                        guard let chat else {
                            log.error(".delivered event \(id), \(service) has no IMChat; can't pass to mautrix")
                            return
                        }

                        self.ipcChannel.writePayload(
                            .init(
                                command: .send_message_status(
                                    BLMessageStatus(
                                        guid: id,
                                        chatGUID: chat.blChatGUID,
                                        status: .delivered,
                                        service: service.rawValue
                                    )
                                )
                            )
                        )
                    case .read, .sending:
                        // don't do anything; these are handled elsewhere
                        break
                    }
                }
            }
            .store(in: &bag)
    }

    public func purgedTransferFailed(_ transfer: IMFileTransfer) {
        self.ipcChannel.writePayload(
            .init(
                id: nil,
                command: .error(
                    .init(
                        code: "file-transfer-failure",
                        message:
                            "Failed to download file transfer: \(transfer.errorDescription ?? transfer.error.description) (\(transfer.error.description))"
                    )
                )
            )
        )
    }
}
