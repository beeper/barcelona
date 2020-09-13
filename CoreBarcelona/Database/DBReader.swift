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

extension Configuration {
    init(trace: @escaping TraceFunction) {
        self.init()
        self.trace = trace
    }
}

//private let dbConfiguration = Configuration { db in
//    print("We query! \(db)")
//}
private let dbConfiguration = Configuration()

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
struct DBReader {
    var pool: DatabasePool
    var eventLoop: EventLoop
    
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
    
    func insert(fileTransfer: IMFileTransfer, path: String) throws -> () {
        try pool.write { db in
            try db.execute(sql: "INSERT INTO attachment ( guid,  original_guid,  created_date,  start_date,  filename,  uti,  mime_type,  transfer_state,  is_outgoing,  transfer_name,  total_bytes) VALUES (   ?,   ?,  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,   ? );", arguments: [fileTransfer.guid, fileTransfer.guid,  Int(fileTransfer.createdDate.timeIntervalSinceReferenceDate), Int(fileTransfer.startDate?.timeIntervalSinceReferenceDate ?? 0), path, fileTransfer.type, fileTransfer.mimeType, 5, !fileTransfer.isIncoming, fileTransfer.transferredFilename, fileTransfer.totalBytes])
        }
    }
}

extension DBReader {
    static var shared: DBReader {
        DBReader(pool: databasePool, eventLoop: defaultEventLoopGroup.next())
    }
}
