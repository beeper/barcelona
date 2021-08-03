//
//  MessageAttachmentJoin.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/14/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

public class MessageAttachmentJoin: Record {
    public override class var databaseTableName: String {
        "message_attachment_join"
    }
    
    public static let message = belongsTo(RawMessage.self, using: ForeignKey(["message_id"], to: ["ROWID"]))
    public static let attachment = belongsTo(RawAttachment.self, using: ForeignKey(["attachment_id"], to: ["ROWID"]))
    
    public required init(row: Row) {
        message_id = row[Columns.message_id]
        attachment_id = row[Columns.attachment_id]
        super.init(row: row)
    }
    
    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.message_id] = message_id
        container[Columns.attachment_id] = attachment_id
    }
    
    public enum Columns: String, ColumnExpression {
        case message_id, attachment_id
    }
    
    public var message_id: Int64?
    public var attachment_id: Int64?
}
