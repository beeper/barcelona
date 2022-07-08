//
//  IPCOut.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 7/8/22.
//

import Foundation
import IMCore
import Barcelona

private extension CBMessageStatusChange {
    var mautrixFriendlyGUID: String? {
        guard let sender = sender else {
            return nil
        }
        
        return "\(message.service ?? "iMessage");\(chat.isGroup ? "+" : "-");\(sender)"
    }
}

func sendUpdatedContact(forHandleID handleID: String) {
    let contact = BLContact.blContact(forHandleID: handleID)
    let command = IPCCommand.contact(contact)
    let payload = IPCPayload(command: command)
    BLWritePayload(payload)
}

func sendUpdatedContact(for handle: IMHandle) {
    sendUpdatedContact(forHandleID: handle.id)
}

func sendMessageSent(withGUID guid: String, service: String, chatGUID: String) {
    let status = BLMessageStatus(sentMessageGUID: guid, onService: service, forChatGUID: chatGUID)
    let command = IPCCommand.send_message_status(status)
    let payload = IPCPayload(command: command)
    BLWritePayload(payload)
}

func sendMessageFailed(withGUID guid: String, code: FZErrorType, service: String, chatGUID: String) {
    let status = BLMessageStatus(guid: guid, chatGUID: chatGUID, status: .failed, service: service, message: code.localizedDescription, statusCode: code.description)
    let command = IPCCommand.send_message_status(status)
    let payload = IPCPayload(command: command)
    BLWritePayload(payload)
}

func sendMessageEvent(_ message: Message) {
    let message = BLMessage(message: message)
    let command = IPCCommand.message(message)
    let payload = IPCPayload(command: command)
    BLWritePayload(payload)
}

private func send(_receipt receipt: BLReadReceipt) {
    let command = IPCCommand.read_receipt(receipt)
    let payload = IPCPayload(command: command)
    BLWritePayload(payload)
}

func sendReadReceipt(change: CBMessageStatusChange) {
    guard change.type == .read else {
        preconditionFailure("sendReadReceipt can only be passed read statuses, you gave me a status with type \(change.type.rawValue)")
    }
    let correl_id = change.sender.flatMap(CBSenderCorrelationController.shared.correlate(fuzzySenderID:))
    let receipt = BLReadReceipt(sender_guid: change.mautrixFriendlyGUID, is_from_me: change.fromMe, chat_guid: change.chat.blChatGUID, read_up_to: change.messageID, correl_id: correl_id)
    send(_receipt: receipt)
}

func sendChatMarkedRead(guid: String, upTo message: String) {
    let receipt = BLReadReceipt(sender_guid: nil, is_from_me: true, chat_guid: guid, read_up_to: message, correl_id: nil)
    send(_receipt: receipt)
}

func sendTyping(guid: String, typing: Bool) {
    let correl_id = IMChatRegistry.shared.existingChat(withGUID: guid).flatMap(CBSenderCorrelationController.shared.correlate(_:))
    let notification = BLTypingNotification(chat_guid: guid, typing: typing, correl_id: correl_id)
    let command = IPCCommand.typing(notification)
    let payload = IPCPayload(command: command)
    BLWritePayload(payload)
}

func sendError(code: String, message: String) {
    let error = ErrorCommand(code: code, message: message)
    let command = IPCCommand.error(error)
    let payload = IPCPayload(command: command)
    BLWritePayload(payload)
}
