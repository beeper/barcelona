//
//  ChatHandleJoin.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

class ChatHandleJoin: Record {
    override class var databaseTableName: String { "chat_handle_join" }
    
    static let chat = belongsTo(RawChat.self, using: ForeignKey([Columns.chat_id], to: [RawChat.Columns.ROWID]))
    static let handle = belongsTo(RawHandle.self, using: ForeignKey([Columns.handle_id], to: [RawHandle.Columns.ROWID]))
    
    required init(row: Row) {
        chat_id = row[Columns.chat_id]
        handle_id = row[Columns.handle_id]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.chat_id] = chat_id
        container[Columns.handle_id] = handle_id
    }
    
    enum Columns: String, ColumnExpression {
        case chat_id, handle_id
    }
    
    var chat_id: Int64?
    var handle_id: Int64?
}
