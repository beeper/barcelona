//
//  Search.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import GRDB
import os.log

extension RawMessage {
    static func joiningOnROWIDsWhenNotEmpty(ROWIDs: [Int64], withColumns columns: [RawMessage.Columns]) -> QueryInterfaceRequest<RawMessage> {
        if ROWIDs.count > 0 {
            return RawMessage.joining(required: RawMessage.messageChatJoin.filter(ROWIDs.contains(ChatMessageJoin.Columns.chat_id))).select(columns)
        } else {
            return RawMessage.select(columns)
        }
    }
}

extension Array where Element : Equatable {
    func intersects(with array: [Element]) -> Bool{
        contains(where: {
            array.contains($0)
        })
    }
    
    func excluding(array: [Element]) -> [Element] {
        filter {
            !array.contains($0)
        }
    }
    
    func including(array: [Element]) -> [Element] {
        filter {
            array.contains($0)
        }
    }
}

extension Array {
    var templatedString: String {
        map { _ in
            "?"
        }.joined(separator: ", ")
    }
}

extension Date {
    static func timeIntervalSince1970FromIMDBDateValue(date rawDate: Double) -> Double {
        let rawDateSmall: Double = Double(rawDate / 1000000000)
        
        return Date(timeIntervalSinceReferenceDate: TimeInterval(rawDateSmall)).timeIntervalSince1970 * 1000
    }
}

private extension QueryInterfaceRequest where T == RawMessage {
    func joiningOnHandlesWhenNotEmpty(handles: [String]) -> Self {
        /// the handle_id is the recipient when from_me is 0, other_handle is the recipient when from_me is 1
        if handles.count > 0 {
            return joining(optional: RawMessage.messageHandleJoin.filter(handles.contains(RawHandle.Columns.id)))
        } else {
            return self
        }
    }
    
    func filterTextWhenNotEmpty(text: String?) -> Self {
        if let text = text, text.count > 0 {
            return filter(RawMessage.Columns.text.uppercased.like("%\(text)%"))
        } else {
            return self
        }
    }
    
    func filterBundleIDWhenNotEmpty(bundleID: String?) -> Self {
        if let bundleID = bundleID, bundleID.count > 0 {
            return filter(RawMessage.Columns.balloon_bundle_id == bundleID)
        } else {
            return self
        }
    }
}

private enum SearchFulfillmentResult {
    case chatIDs([Int64])
    case handleIDs([String: Int64])
}

/// These extensions are used for the search APIs
extension DBReader {
    func queryMessages(withParameters params: MessageQueryParameters) -> Promise<[Message], Error> {
        let limit = params.limit ?? 20
        
        var chatRowIDQuery: Promise<[Int64], Error>
        
        if let chatIdentifiers = params.chats {
            chatRowIDQuery = self.rowIDs(forIdentifiers: chatIdentifiers).then {
                Array($0.values).flatMap { $0 }
            }
        } else {
            chatRowIDQuery = .success([])
        }
        
        var handles = params.handles ?? []
        
        /// Resolves contact IDs to all handles associated
        if let contacts = params.contacts {
            let handleIDs = contacts.reduce(into: [String]()) { handleIDs, contactID in
                handleIDs.append(contentsOf: IMHandleRegistrar.sharedInstance().handles(forCNIdentifier: contactID).map {
                    $0.id
                })
            }
            
            handles.append(contentsOf: handleIDs)
        }
        
        /// Resolve the ROWIDs of any provided chat identifiers
        return chatRowIDQuery.flatMap { ROWIDs -> Promise<ArraySlice<RawMessage>, Error> in
            /// Get database handle
            Promise { resolve, reject in
                databasePool.asyncRead { result in
                    #if DEBUG
                    os_log("Performing message query with chat identifiers %@ handles %@ text %@ limit %d", params.chats ?? [], handles, params.search ?? "<<no search>>", params.limit ?? 20)
                    #endif
                    
                    /// Performs a query for either me or not me (IMCore handle that are associated with an account function differently)
                    let query: ([String]?, Bool?) throws -> [RawMessage] = { handles, fromMe in
                        var dbQuery = RawMessage
                            .joiningOnROWIDsWhenNotEmpty(ROWIDs: ROWIDs, withColumns: [.guid, .ROWID, .date])
                        
                        if let handles = handles, let fromMe = fromMe {
                            dbQuery = dbQuery
                                .joiningOnHandlesWhenNotEmpty(handles: handles)
                                .filter(RawMessage.Columns.is_from_me == (fromMe ? 1 : 0))
                        }
                        
                        return try dbQuery.filterTextWhenNotEmpty(text: params.search)
                            .filterBundleIDWhenNotEmpty(bundleID: params.bundle_id)
                            .order(RawMessage.Columns.date.desc)
                            .limit(limit)
                            .fetchAll(try result.get())
                    }
                    
                    let allLoginHandles = Registry.sharedInstance.uniqueMeHandleIDs
                    
                    let loginHandles = handles.including(array: allLoginHandles)
                    let otherHandles = handles.excluding(array: allLoginHandles)
                    
                    var messagesFromMe: [RawMessage]!
                    
                    do {
                        /// Only do a split query when handles are provided
                        if loginHandles.count > 0 || otherHandles.count > 0 {
                            messagesFromMe = loginHandles.count > 0 ? try query(loginHandles, true) : []
                            messagesFromMe.append(contentsOf: otherHandles.count > 0 ? try query(otherHandles, false) : [])
                        } else {
                            messagesFromMe = try query(nil, nil)
                        }
                    } catch {
                        return reject(error)
                    }
                    
                    messagesFromMe.sort(by: { m1, m2 in
                        (m1.date ?? 0) > (m2.date ?? 0)
                    })
                    
                    resolve(messagesFromMe.prefix(limit))
                }
            }
        }.then { items -> Promise<[Message], Error> in
            let messageROWIDs = items.map { $0.ROWID }
            
            let messageROWIDtoGUID = items.reduce(into: [Int64: String]()) { ledger, item in
                guard let guid = item.guid else {
                    return
                }
                
                ledger[item.ROWID] = guid
            }
            
            /// Preload all the chat identifiers in bulk to reduce overhead later
            return self.chatIdentifiers(forMessageRowIDs: messageROWIDs).then { chatIdentifiers -> Promise<[Message], Error> in
                var masterMap: [String: [String]] = [:]
                
                /// Sort the results into a dictionary of <Chat Identifier, [Message GUID]>
                chatIdentifiers.forEach {
                    guard let guid = messageROWIDtoGUID[$0.key] else {
                        return
                    }
                    
                    if masterMap[$0.value] == nil {
                        masterMap[$0.value] = []
                    }
                    
                    masterMap[$0.value]!.append(guid)
                }
                
                /// Take each chunk of chat<->messages and resolve them
                return Promise.whenAllSucceed(masterMap.map {
                    Message.messages(withGUIDs: $0.value, in: $0.key)
                }).then {
                    $0.flatMap {
                        $0
                    }.sorted { m1, m2 in
                        m1.time > m2.time
                    }
                }
            }
        }
    }
    
    func attachments(matchingParameters parameters: AttachmentSearchParameters) -> Promise<[InternalAttachment], Error> {
        parameters.chatROWIDs().then { ROWIDs in
            Promise { resolve, reject in
                databasePool.asyncRead { result in
                    var stmt = SQLLiteral(sql: """
        SELECT attachment.ROWID, attachment.guid, attachment.original_guid, attachment.filename, attachment.total_bytes, attachment.is_outgoing, attachment.mime_type, attachment.uti FROM attachment
    """, arguments: [])
                    
                    var didAddFirstStatement = false
                    
                    if ROWIDs.count > 0 {
                        stmt.append(literal: SQLLiteral(sql:
    """
     INNER JOIN message_attachment_join ON attachment.ROWID = message_attachment_join.attachment_id
     INNER JOIN message ON message_attachment_join.message_id = message.ROWID
     INNER JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
     INNER JOIN chat ON chat_message_join.chat_id = chat.ROWID
     AND chat.ROWID IN (\(ROWIDs.templatedString))
    """, arguments: .init(ROWIDs)))
                        
                        didAddFirstStatement = true
                    }
                    
                    stmt.append(sql: "\(didAddFirstStatement ? " AND" : " WHERE") attachment.hide_attachment == 0")
                    didAddFirstStatement = true
                    
                    if let mimes = parameters.mime, mimes.count > 0 {
                        stmt.append(literal: SQLLiteral(sql: " AND attachment.mime_type IN (\(mimes.templatedString))", arguments: .init(mimes)))
                    } else if let likeMIME = parameters.likeMIME {
                        stmt.append(literal: SQLLiteral(sql: " AND attachment.mime_type LIKE ?", arguments: ["\(likeMIME)%"]))
                    }
                    
                    if let utis = parameters.uti, utis.count > 0 {
                        stmt.append(literal: SQLLiteral(sql: " AND attachment.uti IN (\(utis.templatedString))", arguments: .init(utis)))
                    } else if let likeUTI = parameters.likeUTI {
                        stmt.append(literal: SQLLiteral(sql: " AND attachment.uti LIKE ?", arguments: ["\(likeUTI)%"]))
                    }
                    
                    if let name = parameters.name {
                        stmt.append(literal: SQLLiteral(sql: " AND LOWER(attachment.filename) LIKE ?", arguments: ["%\(name)%"]))
                    }
                    
                    stmt.append(sql: " ORDER BY attachment.ROWID DESC")
                    
                    if let limit = parameters.limit {
                        stmt.append(literal: SQLLiteral(sql: " LIMIT ?", arguments: [limit]))
                    }
                    
                    do {
                        print(stmt.sql)
                        
                        let attachments: [RawAttachment] = try RawAttachment.fetchAll(try result.get(), sql: stmt.sql, arguments: stmt.arguments, adapter: nil)
                        
                        let attachmentROWIDs = attachments.compactMap {
                            $0.ROWID
                        }
                        
                        let messageAttachmentJoins: [MessageAttachmentJoin] = try MessageAttachmentJoin
                            .filter(attachmentROWIDs.contains(MessageAttachmentJoin.Columns.attachment_id))
                            .fetchAll(try result.get())
                        
                        let messageROWIDs = messageAttachmentJoins.compactMap {
                            $0.message_id
                        }
                        
                        let messages: [RawMessage] = try RawMessage
                            .select([RawMessage.Columns.ROWID, RawMessage.Columns.is_from_me, RawMessage.Columns.handle_id, RawMessage.Columns.service, RawMessage.Columns.date])
                            .filter(messageROWIDs.contains(RawMessage.Columns.ROWID))
                            .fetchAll(try result.get())
                        
                        let handleROWIDs = messages.filter {
                            $0.is_from_me == 0
                        }.compactMap {
                            $0.handle_id
                        }
                        
                        let handles: [RawHandle] = try RawHandle
                            .select([RawHandle.Columns.ROWID, RawHandle.Columns.id])
                            .filter(handleROWIDs.contains(RawHandle.Columns.ROWID))
                            .fetchAll(try result.get())
                        
                        let handlesLedger = handles.reduce(into: [Int64: RawHandle]()) { ledger, handle in
                            guard let ROWID = handle.ROWID else {
                                return
                            }
                            
                            ledger[ROWID] = handle
                        }
                        
                        let messagesLedger = messages.reduce(into: [Int64: RawMessage]()) { ledger, message in
                            ledger[message.ROWID] = message
                        }
                        
                        let messageAttachmentLedger = messageAttachmentJoins.reduce(into: [Int64: (RawMessage?, RawHandle?)]()) { ledger, join in
                            guard let messageID = join.message_id, let attachmentID = join.attachment_id else {
                                return
                            }
                            
                            var handle: RawHandle? = nil
                            
                            if let handleID = messagesLedger[messageID]?.handle_id {
                                handle = handlesLedger[handleID]
                            }
                            
                            ledger[attachmentID] = (messagesLedger[messageID], handle)
                        }
                        
                        /// Get chat identifier for origin
                        self.chatIdentifiers(forMessageRowIDs: Array(messagesLedger.keys)).whenSuccess { chatIdentifierLdeger in
                            var attachments = attachments.compactMap { attachment -> InternalAttachment? in
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
                                    
                                    chat = chatIdentifierLdeger[rawMessage.ROWID]
                                    
                                    if rawMessage.is_from_me == 0 {
                                        sender = messageAttachmentLedger[ROWID]?.1?.id
                                    } else {
                                        if let service = rawMessage.service, let handle = Registry.sharedInstance.suitableHandle(for: service) {
                                            sender = handle.id
                                        }
                                    }
                                }
                                
                                return attachment.internalAttachment(withOrigin: ResourceOrigin(chatID: chat, handleID: sender, date: date))
                            }
                            
                            attachments.sort { attachment1, attachment2 in
                                (attachment1.origin?.date ?? 0) > (attachment2.origin?.date ?? 0)
                            }
                            
                            resolve(attachments)
                        }
                    } catch {
                        reject(error)
                    }
                }
            }
        }
    }
    
    func messages(matching text: String, limit: Int) -> Promise<[Message], Error> {
        Promise { resolve, reject in
            pool.asyncRead { result in
                switch result {
                case .failure(let error):
                    reject(error)
                    return
                case .success(let db):
                    do {
                        // MARK: - Message table search
                        let results = try RawMessage
                            .select(RawMessage.Columns.guid, as: String.self)
                            .filter(RawMessage.Columns.text.uppercased.like("%\(text)%"))
                            .order(RawMessage.Columns.date.desc)
                            .limit(limit)
                            .fetchAll(db)
                        
                        Message.messages(withGUIDs: results).then {
                            $0.sorted(by: { m1, m2 in
                                m1.time > m2.time
                            })
                        }.pipe(resolve, reject)
                    } catch {
                        reject(error)
                    }
                }
            }
        }
    }
}
