//
//  Reader.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import IMCore
import Foundation
import Vapor
import GRDB

#if os(iOS)
let db = try! DatabasePool(path: "/var/mobile/Library/SMS/sms.db")
#else
let db = try! DatabasePool(path: ("~/Library/Messages/chat.db" as NSString).expandingTildeInPath)
#endif

/**
 Interface for reading the chat.db file.
 
 DO NOT MAKE WRITES! THIS IS FOR READING ONLY!
 */
// MARK: - I REPEAT DO NOT MAKE WRITES TO THE DATABASE DIRECTLY! THIS IS FOR READING ONLY!
struct DBReader {
    var pool: DatabasePool
    var eventLoop: EventLoop
    
    func resolveSenderID(forMessage message: RawMessage, in db: Database) throws -> String? {
        if message.is_from_me == 1 {
            return Registry.sharedInstance.iMessageAccount()!.arrayOfAllIMHandles[0].id
        } else {
            guard let handleRowID = message.handle_id, let rawHandle = try RawHandle.fetchOne(db, sql: "SELECT * FROM handle WHERE ROWID = ?", arguments: [handleRowID]) else { return nil }
            
            return rawHandle.id
        }
    }
    
    func insert(fileTransfer: IMFileTransfer, path: String) throws -> () {
        try pool.write { db in
            try db.execute(sql: "INSERT INTO attachment ( guid,  original_guid,  created_date,  start_date,  filename,  uti,  mime_type,  transfer_state,  is_outgoing,  transfer_name,  total_bytes) VALUES (   ?,   ?,  ?,   ?,   ?,   ?,   ?,   ?,   ?,   ?,   ? );", arguments: [fileTransfer.guid, fileTransfer.guid,  Int(fileTransfer.createdDate.timeIntervalSinceReferenceDate), Int(fileTransfer.startDate?.timeIntervalSinceReferenceDate ?? 0), path, fileTransfer.type, fileTransfer.mimeType, 5, !fileTransfer.isIncoming, fileTransfer.transferredFilename, fileTransfer.totalBytes])
        }
    }
}
