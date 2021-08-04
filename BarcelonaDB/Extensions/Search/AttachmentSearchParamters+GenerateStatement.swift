//
//  AttachmentSearchParamters+GenerateStatement.swift
//  Barcelona
//
//  Created by Eric Rabil on 7/30/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Foundation
import BarcelonaFoundation
import GRDB

fileprivate extension AttachmentSearchParameters {
    func statement(forChatROWIDs ROWIDs: [Int64]) -> SQLLiteral {
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
        
        if let mimes = mime, mimes.count > 0 {
            stmt.append(literal: SQLLiteral(sql: " AND attachment.mime_type IN (\(mimes.templatedString))", arguments: .init(mimes)))
        } else if let likeMIME = likeMIME {
            stmt.append(literal: SQLLiteral(sql: " AND attachment.mime_type LIKE ?", arguments: ["\(likeMIME)%"]))
        }
        
        if let utis = uti, utis.count > 0 {
            stmt.append(literal: SQLLiteral(sql: " AND attachment.uti IN (\(utis.templatedString))", arguments: .init(utis)))
        } else if let likeUTI = likeUTI {
            stmt.append(literal: SQLLiteral(sql: " AND attachment.uti LIKE ?", arguments: ["\(likeUTI)%"]))
        }
        
        if let name = name {
            stmt.append(literal: SQLLiteral(sql: " AND LOWER(attachment.filename) LIKE ?", arguments: ["%\(name)%"]))
        }
        
        stmt.append(sql: " ORDER BY attachment.ROWID DESC")
        
        if let limit = limit {
            stmt.append(literal: SQLLiteral(sql: " LIMIT ?", arguments: [limit]))
        }
        
        return stmt
    }
}

internal extension AttachmentSearchParameters {
    func loadRawAttachments() -> Promise<[RawAttachment]> {
        chatROWIDs().then { ROWIDs in
            self.statement(forChatROWIDs: ROWIDs)
        }.then { stmt in
            DBReader.shared.read { db in
                try RawAttachment.fetchAll(db, sql: stmt.sql, arguments: stmt.arguments, adapter: nil)
            }
        }
    }
}
