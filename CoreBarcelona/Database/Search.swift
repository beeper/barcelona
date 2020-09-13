//
//  Search.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import GRDB
import NIO

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
                        .order(RawMessage.Columns.date.desc)
                        .limit(limit)
                        .fetchAll(db)
                    
                    Message.messages(withGUIDs: results).map {
                        $0.sorted(by: { m1, m2 in
                            m1.time! > m2.time!
                        }).representation
                    }.cascade(to: promise)
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
}
