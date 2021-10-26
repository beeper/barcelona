//
//  ChatMessageJoin.swift
//  imcore-rest
//
//  Created by Eric Rabil on 8/8/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

/**
 Represents the chat-message join table in the chat.db file
 */
public class ChatMessageJoin: Record {
    public override class var databaseTableName: String { "chat_message_join" }
    
    public static let message = belongsTo(RawMessage.self, using: ForeignKey(["message_id"], to: ["ROWID"]))
    
    public  required init(row: Row) {
        chat_id = row[Columns.chat_id]
        message_id = row[Columns.message_id]
        message_date = row[Columns.message_date]
        super.init(row: row)
    }
    
    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.chat_id] = chat_id
        container[Columns.message_id] = message_id
        container[Columns.message_date] = message_date
    }
    
    public enum Columns: String, ColumnExpression {
        case chat_id, message_id, message_date
    }
    
    public var chat_id: Int64?
    public var message_id: Int64?
    public var message_date: Int64?
}
