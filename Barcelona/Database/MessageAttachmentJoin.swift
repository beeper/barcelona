//
//  MessageAttachmentJoin.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

class MessageAttachmentJoin: Record {
    override class var databaseTableName: String {
        "message_attachment_join"
    }
    
    static let message = belongsTo(RawMessage.self, using: ForeignKey(["message_id"], to: ["ROWID"]))
    static let attachment = belongsTo(RawAttachment.self, using: ForeignKey(["attachment_id"], to: ["ROWID"]))
    
    required init(row: Row) {
        message_id = row[Columns.message_id]
        attachment_id = row[Columns.attachment_id]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.message_id] = message_id
        container[Columns.attachment_id] = attachment_id
    }
    
    enum Columns: String, ColumnExpression {
        case message_id, attachment_id
    }
    
    var message_id: Int64?
    var attachment_id: Int64?
}
