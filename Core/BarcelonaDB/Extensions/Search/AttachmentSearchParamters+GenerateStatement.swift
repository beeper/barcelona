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
        var components: [SQLLiteral] = [
            """
            SELECT attachment.ROWID, attachment.guid, attachment.original_guid, attachment.filename, attachment.total_bytes, attachment.is_outgoing, attachment.mime_type, attachment.uti FROM attachment
            """
        ]
        
        var didAddFirstStatement = false
        
        if ROWIDs.count > 0 {
            components.append("""
            INNER JOIN message_attachment_join ON attachment.ROWID = message_attachment_join.attachment_id
            INNER JOIN message ON message_attachment_join.message_id = message.ROWID
            INNER JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
            INNER JOIN chat ON chat_message_join.chat_id = chat.ROWID
            WHERE chat.ROWID IN \(ROWIDs)
            """)
            didAddFirstStatement = true
        }
        
        components.append("\(didAddFirstStatement ? " AND" : " WHERE") attachment.hide_attachment == 0")
        didAddFirstStatement = true
        
        if let mimes = mime, mimes.count > 0 {
            components.append("""
            AND attachment.mime_type IN \(mimes)
            """)
        } else if let likeMIME = likeMIME {
            components.append("""
            AND attachment.mime_type LIKE \(likeMIME + "%")
            """)
        }
        
        if let utis = uti, utis.count > 0 {
            components.append("""
            AND attachment.uti IN \(utis)
            """)
        } else if let likeUTI = likeUTI {
            components.append("""
            AND attachment.uti LIKE \(likeUTI + "%")
            """)
        }
        
        if let name = name {
            components.append("""
            AND LOWER(attachment.filename) LIKE \("%" + name + "%")
            """)
        }
        
        components.append("""
        ORDER BY attachment.ROWID DESC
        """)
        
        if let limit = limit {
            components.append("LIMIT \(limit)")
        }
        
        return components.joined(separator: "\n")
    }
}

internal extension AttachmentSearchParameters {
    func loadRawAttachments() -> Promise<[RawAttachment]> {
        chatROWIDs().then { ROWIDs in
            self.statement(forChatROWIDs: ROWIDs)
        }.then { stmt in
            DBReader.shared.read { db in
                let (sql, arguments) = try stmt.build(db)
                return try RawAttachment.fetchAll(db, sql: sql, arguments: arguments, adapter: nil)
            }
        }
    }
}
