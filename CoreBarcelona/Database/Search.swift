//
//  Search.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import GRDB

private class Search: Record {
    override class var databaseTableName: String { "search" }
    
    required init(row: Row) {
        guid = row[Columns.guid]
        text = row[Columns.text]
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.guid] = guid
        container[Columns.text] = text
    }
    
    enum Columns: String, ColumnExpression {
        case guid, text
    }
    
    var guid: String
    var text: String?
}

extension DBReader {
    func messages(matching text: String, limit: Int) -> EventLoopFuture<BulkMessageRepresentation> {
        let promise = eventLoop.makePromise(of: BulkMessageRepresentation.self)
        
        pool.asyncRead { result in
            switch result {
            case .failure(let error):
                promise.fail(error)
                return
            case .success(let db):
                do {
                    // MARK: - Message table search
                    let results = try RawMessage
                        .select(RawMessage.Columns.guid, as: String.self)
                        .filter(RawMessage.Columns.text.uppercased.like("%\(text)%"))
                        .limit(limit)
                        .fetchAll(db)
                    
                    Message.messages(withGUIDs: results).map {
                        $0.representation
                    }.cascade(to: promise)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
}
