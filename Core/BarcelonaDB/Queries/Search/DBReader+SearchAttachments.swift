//
//  DBReader+SearchAttachments.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import BarcelonaFoundation
import Foundation
import GRDB

public protocol IMServiceRegistrationProvider {
    func handle(forService service: String) -> String?
}

#if canImport(IMCore)
import IMCore

private class IMServiceRegistrationProviderImpl: IMServiceRegistrationProvider {
    static let shared = IMServiceRegistrationProviderImpl()

    func handle(forService service: String) -> String? {
        IMAccountController.__sharedInstance().bestAccount(forService: service)?.loginIMHandle?.id
    }
}
#endif

extension DBReader {
    public func attachments(
        matchingParameters parameters: AttachmentSearchParameters,
        serviceRegistrationProvider: IMServiceRegistrationProvider? = nil
    ) async throws -> [RawAttachment] {
        func getMessages(_ db: Database, attachments: [RawAttachment]) throws -> ([RawMessage], [MessageAttachmentJoin])
        {
            let messageAttachmentJoins: [MessageAttachmentJoin] =
                try MessageAttachmentJoin
                .filter(attachments.compactMap(\.ROWID).contains(MessageAttachmentJoin.Columns.attachment_id))
                .fetchAll(db)

            let messageROWIDs = messageAttachmentJoins.compactMap(\.message_id)

            let messages: [RawMessage] =
                try RawMessage
                .select([
                    RawMessage.Columns.ROWID, RawMessage.Columns.is_from_me, RawMessage.Columns.handle_id,
                    RawMessage.Columns.service, RawMessage.Columns.date,
                ])
                .filter(messageROWIDs.contains(RawMessage.Columns.ROWID))
                .fetchAll(db)

            return (messages, messageAttachmentJoins)
        }

        func getLedgers(_ db: Database, messages: [RawMessage]) throws -> ([Int64: RawMessage], [Int64: RawHandle]) {
            let messagesLedger = messages.dictionary(keyedBy: \.ROWID)

            let handleROWIDs =
                messages.filter {
                    $0.is_from_me == 0
                }
                .compactMap(\.handle_id)

            let handles: [RawHandle] =
                try RawHandle
                .select([RawHandle.Columns.ROWID, RawHandle.Columns.id])
                .filter(handleROWIDs.contains(RawHandle.Columns.ROWID))
                .fetchAll(db)

            let handlesLedger = handles.dictionary(keyedBy: \.ROWID)

            return (messagesLedger, handlesLedger)
        }

        let attachments = try await parameters.loadRawAttachments()

        let (messagesLedger, messageAttachmentLedger) = try await read {
            db -> ([Int64: RawMessage], [Int64: (RawMessage?, RawHandle?)]) in
            let (messages, messageAttachmentJoins) = try getMessages(db, attachments: attachments)

            let (messagesLedger, handlesLedger) = try getLedgers(db, messages: messages)

            let messageAttachmentLedger = messageAttachmentJoins.reduce(into: [Int64: (RawMessage?, RawHandle?)]()) {
                ledger,
                join in
                guard let messageID = join.message_id, let attachmentID = join.attachment_id else {
                    return
                }

                var handle: RawHandle? = nil

                if let handleID = messagesLedger[messageID]?.handle_id {
                    handle = handlesLedger[handleID]
                }

                ledger[attachmentID] = (messagesLedger[messageID], handle)
            }

            return (messagesLedger, messageAttachmentLedger)
        }

        /// Get chat identifier for origin
        let chatIdentifierLedger = try await chatIdentifiers(forMessageRowIDs: Array(messagesLedger.keys))

        #if canImport(IMCore)
        let serviceRegistrationProvider = Optional(
            serviceRegistrationProvider ?? IMServiceRegistrationProviderImpl.shared
        )
        #endif

        return
            attachments.compactMap { attachment -> RawAttachment? in
                guard let ROWID = attachment.ROWID else {
                    return nil
                }

                var sender: String? = nil
                var chat: String?
                var date: Double? = nil

                if let rawMessage = messageAttachmentLedger[ROWID]?.0 {
                    if let rawDate = rawMessage.date {
                        date = Date.timeIntervalSince1970FromIMDBDateValue(date: Double(rawDate))
                    }

                    chat = chatIdentifierLedger[rawMessage.ROWID]

                    if rawMessage.is_from_me == 0 {
                        sender = messageAttachmentLedger[ROWID]?.1?.id
                    } else {
                        if let service = rawMessage.service {
                            sender = serviceRegistrationProvider?.handle(forService: service)
                        }
                    }
                }

                attachment.origin = ResourceOrigin(chatID: chat, handleID: sender, date: date)
                return attachment
            }
            .sorted(usingKey: \.origin?.date, withDefaultValue: 0, by: >)
    }
}
