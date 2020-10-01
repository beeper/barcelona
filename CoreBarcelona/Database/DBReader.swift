//
//  Reader.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMCore
import GRDB
import NIO
import os.log

extension Configuration {
    init(trace: @escaping TraceFunction) {
        self.init()
        self.trace = trace
    }
}

#if DEBUG
private let dbConfiguration = Configuration { db in
    os_log("Performing SQL query: %{private}@", type: .debug, db)
}
#else
private let dbConfiguration = Configuration()
#endif

#if os(iOS)
let databasePool = try! DatabasePool(path: "/var/mobile/Library/SMS/sms.db", configuration: dbConfiguration)
#else
let databasePool = try! DatabasePool(path: ("~/Library/Messages/chat.db" as NSString).expandingTildeInPath, configuration: dbConfiguration)
#endif

private let defaultEventLoopGroup = MultiThreadedEventLoopGroup.init(numberOfThreads: 3)

/**
 Interface for reading the chat.db file.
 
 DO NOT MAKE WRITES! THIS IS FOR READING ONLY!
 */
// MARK: - I REPEAT DO NOT MAKE WRITES TO THE DATABASE DIRECTLY! THIS IS FOR READING ONLY!
public struct DBReader {
    var pool: DatabasePool
    var eventLoop: EventLoop
    
    init(pool: DatabasePool = databasePool, eventLoop: EventLoop = defaultEventLoopGroup.next()) {
        self.pool = pool
        self.eventLoop = eventLoop
    }
    
    func resolveSenderID(forMessage message: RawMessage) -> EventLoopFuture<String?> {
        resolveSenderIDs(forMessages: [message]).map {
            $0[message.ROWID]
        }
    }
    
    func resolveSenderIDs(forMessages messages: [RawMessage]) -> EventLoopFuture<[Int64: String]> {
        let promise = eventLoop.makePromise(of: [Int64: String].self)
        
        pool.asyncRead {
            switch $0 {
            case .failure(let error):
                promise.fail(error)
            case .success(let db):
                do {
                    let handleRowIDs = messages.filter {
                        $0.is_from_me != 1
                    }.compactMap {
                        $0.handle_id
                    }
                    
                    let handles = try RawHandle
                        .select([RawHandle.Columns.ROWID, RawHandle.Columns.id])
                        .filter(handleRowIDs.contains(RawHandle.Columns.ROWID))
                    .fetchAll(db)
                    
                    let handleLedger = handles.reduce(into: [Int64: String]()) { (ledger, partialHandle) in
                        guard let ROWID = partialHandle.ROWID, let id = partialHandle.id else {
                            return
                        }
                        
                        ledger[ROWID] = id
                    }
                    
                    promise.succeed(messages.reduce(into: [Int64: String]()) { (ledger, message) in
                        if message.is_from_me == 1 {
                            ledger[message.ROWID] = Registry.sharedInstance.iMessageAccount()!.arrayOfAllIMHandles[0].id
                        } else {
                            guard let handleID = message.handle_id, let handle = handleLedger[handleID] else {
                                return
                            }
                            
                            ledger[message.ROWID] = handle
                        }
                    })
                } catch {
                    promise.fail(error)
                }
            }
        }
        
        return promise.futureResult
    }
    
    func insert(fileTransfer: IMFileTransfer, path: String) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        
        pool.asyncWrite({ db in
            try db.execute(sql: "INSERT INTO attachment ( guid,  original_guid,  created_date,  start_date,  filename,  uti,  mime_type,  transfer_state,  is_outgoing,  transfer_name,  total_bytes) VALUES (   ?,   ?,  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,   ? );", arguments: [fileTransfer.guid, fileTransfer.guid,  Int(fileTransfer.createdDate.timeIntervalSinceReferenceDate), Int(fileTransfer.startDate?.timeIntervalSinceReferenceDate ?? 0), path, fileTransfer.type, fileTransfer.mimeType, 5, !fileTransfer.isIncoming, fileTransfer.transferredFilename, fileTransfer.totalBytes])
        }, completion: { db, result in
            switch result {
            case .failure(let error):
                promise.fail(error)
            case .success(_):
                promise.succeed(())
            }
        })
        
        return promise.futureResult
    }
}

typealias HandleTimestampRecord = (handle_id: String, date: Int64, chat_id: String)

let handleTimestampQuery = """
SELECT DISTINCT handle.id AS handle_id, MAX(message.date) AS date, chat.chat_identifier AS chat_id FROM message
INNER JOIN handle ON message.handle_id = handle.ROWID
INNER JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
INNER JOIN chat ON chat_message_join.chat_id = chat.ROWID AND chat.chat_identifier IN (?) GROUP BY handle_id, chat_identifier ORDER BY message.date DESC
"""

private class HandleTimestampSynthesized: Record {
    override class var databaseTableName: String { "chat_message_join" }
    
    required init(row: Row) {
        handle_id = row[Columns.handle_id]
        chat_id = row[Columns.chat_id]
        date = row[Columns.date]
        super.init(row: row)
    }
    
    enum Columns: String, ColumnExpression {
        case handle_id, chat_id, date
    }
    
    var handle_id: String
    var chat_id: String
    var date: Int64
    
    var record: HandleTimestampRecord {
        (handle_id: handle_id, date: date, chat_id: chat_id)
    }
}

private extension Array where Element == HandleTimestampSynthesized {
    var records: [HandleTimestampRecord] {
        map {
            $0.record
        }
    }
}

extension DBReader {
    func handleTimestampRecords(forChatIdentifiers chatIDs: [String]) -> EventLoopFuture<[HandleTimestampRecord]> {
        let promise = eventLoop.makePromise(of: [HandleTimestampRecord].self)
        
        pool.asyncRead { result in
//            try db.get().execute(sql: <#T##String#>)
            do {
                let db = try result.get()
                
                os_signpost(.begin, log: Logging.Database, name: "Query time-sorted participants")
                
                let stmt = try db.makeSelectStatement(sql:
"""
SELECT DISTINCT handle.id AS handle_id, MAX(message.date) AS date, chat.chat_identifier AS chat_id FROM message
INNER JOIN handle ON message.handle_id = handle.ROWID
INNER JOIN chat_message_join ON message.ROWID = chat_message_join.message_id
INNER JOIN chat ON chat_message_join.chat_id = chat.ROWID AND chat.chat_identifier IN (\(chatIDs.templatedString))  GROUP BY handle_id, chat_identifier ORDER BY message.date DESC
""")
//                let records = try HandleTimestampSynthesized.select(literal: .init).fetchAll(db)
                
                try stmt.setArguments(StatementArguments(chatIDs))
                let results = try Array(try HandleTimestampSynthesized.fetchCursor(stmt))
                
                os_signpost(.end, log: Logging.Database, name: "Query time-sorted participants")
                
                promise.succeed(results.records)
            } catch {
                promise.fail(error)
            }
        }
        
        return promise.futureResult
    }
}

extension DBReader {
    static var shared: DBReader {
        DBReader(pool: databasePool, eventLoop: defaultEventLoopGroup.next())
    }
}
