//
//  ChatHandleJoin.swift
//  CoreBarcelona
//
//  Created by Eric Rabil on 9/16/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB

public class ChatHandleJoin: Record {
    public override class var databaseTableName: String { "chat_handle_join" }

    public static let chat = belongsTo(RawChat.self, using: ForeignKey([Columns.chat_id], to: [RawChat.Columns.ROWID]))
    public static let handle = belongsTo(
        RawHandle.self,
        using: ForeignKey([Columns.handle_id], to: [RawHandle.Columns.ROWID])
    )

    public required init(row: Row) {
        chat_id = row[Columns.chat_id]
        handle_id = row[Columns.handle_id]
        super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) {
        container[Columns.chat_id] = chat_id
        container[Columns.handle_id] = handle_id
    }

    public enum Columns: String, ColumnExpression {
        case chat_id, handle_id
    }

    public var chat_id: Int64?
    public var handle_id: Int64?
}
