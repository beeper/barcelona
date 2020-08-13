//
//  RawAttachment.swift
//  imessage-rest
//
//  Created by Eric Rabil on 8/12/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import Vapor
import GRDB

class RawAttachment: Record {
    override class var databaseTableName: String { "attachment" }
    
    required init(row: Row) {
        ROWID = row[Columns.ROWID]
        guid = row[Columns.guid]
        created_date = row[Columns.created_date]
        start_date = row[Columns.start_date]
        filename = row[Columns.filename]
        uti = row[Columns.uti]
        mime_type = row[Columns.mime_type]
        transfer_state = row[Columns.transfer_state]
        is_outgoing = row[Columns.is_outgoing]
        user_info = row[Columns.user_info]
        transfer_name = row[Columns.transfer_name]
        total_bytes = row[Columns.total_bytes]
        is_sticker = row[Columns.is_sticker]
        sticker_user_info = row[Columns.sticker_user_info]
        attribution_info = row[Columns.attribution_info]
        hide_attachment = row[Columns.hide_attachment]
        ck_sync_state = row[Columns.ck_sync_state]
        ck_server_change_token_blob = row[Columns.ck_server_change_token_blob]
        ck_record_id = row[Columns.ck_record_id]
        original_guid = row[Columns.original_guid]
        sr_ck_sync_state = row[Columns.sr_ck_sync_state]
        sr_ck_server_change_token_blob = row[Columns.sr_ck_server_change_token_blob]
        sr_ck_record_id = row[Columns.sr_ck_record_id]
        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.ROWID] = ROWID
        container[Columns.guid] = guid
        container[Columns.created_date] = created_date
        container[Columns.start_date] = start_date
        container[Columns.filename] = filename
        container[Columns.uti] = uti
        container[Columns.mime_type] = mime_type
        container[Columns.transfer_state] = transfer_state
        container[Columns.is_outgoing] = is_outgoing
        container[Columns.user_info] = user_info
        container[Columns.transfer_name] = transfer_name
        container[Columns.total_bytes] = total_bytes
        container[Columns.is_sticker] = is_sticker
        container[Columns.sticker_user_info] = sticker_user_info
        container[Columns.attribution_info] = attribution_info
        container[Columns.hide_attachment] = hide_attachment
        container[Columns.ck_sync_state] = ck_sync_state
        container[Columns.ck_server_change_token_blob] = ck_server_change_token_blob
        container[Columns.ck_record_id] = ck_record_id
        container[Columns.original_guid] = original_guid
        container[Columns.sr_ck_sync_state] = sr_ck_sync_state
        container[Columns.sr_ck_server_change_token_blob] = sr_ck_server_change_token_blob
        container[Columns.sr_ck_record_id] = sr_ck_record_id
    }

    enum Columns: String, ColumnExpression {
        case ROWID, guid, created_date, start_date, filename, uti, mime_type, transfer_state, is_outgoing, user_info, transfer_name, total_bytes, is_sticker, sticker_user_info, attribution_info, hide_attachment, ck_sync_state, ck_server_change_token_blob, ck_record_id, original_guid, sr_ck_sync_state, sr_ck_server_change_token_blob, sr_ck_record_id
    }

    var ROWID: Int64?
    var guid: String?
    var created_date: Int64?
    var start_date: Int64?
    var filename: String?
    var uti: String?
    var mime_type: String?
    var transfer_state: Int64?
    var is_outgoing: Int64?
    var user_info: Data?
    var transfer_name: String?
    var total_bytes: Int64?
    var is_sticker: Int64?
    var sticker_user_info: Data?
    var attribution_info: Data?
    var hide_attachment: Int64?
    var ck_sync_state: Int64?
    var ck_server_change_token_blob: Data?
    var ck_record_id: String?
    var original_guid: String?
    var sr_ck_sync_state: Int64?
    var sr_ck_server_change_token_blob: Data?
    var sr_ck_record_id: String?
}

struct InternalAttachmentRepresentation {
    var guid: String
    var path: String
    var bytes: UInt64
    var incoming: Bool
    var mime: String?
    
    private var account: IMAccount {
        Registry.sharedInstance.iMessageAccount()!
    }
    
    private var transferCenter: IMFileTransferCenter {
        IMFileTransferCenter.sharedInstance()!
    }
    
    var fileTransfer: IMFileTransfer {
        if let transfer = transferCenter.transfer(forGUID: guid) {
            return transfer
        }
        
        let url = URL(string: "file://\(path)")!
        let transfer = IMFileTransfer()._init(withGUID: guid, filename: url.lastPathComponent, isDirectory: false, localURL: url, account: account.uniqueID, otherPerson: nil, totalBytes: bytes, hfsType: 0, hfsCreator: 0, hfsFlags: 0, isIncoming: false)!
        
        transfer.transferredFilename = url.lastPathComponent
        
        if let mime = mime {
            transfer.setValue(mime, forKey: "_mimeType")
            transfer.setValue(IMFileManager.defaultHFS()!.utiType(ofMimeType: mime), forKey: "_utiType")
        }
        
        let center = IMFileTransferCenter.sharedInstance()!
        
        center._addTransfer(transfer, toAccount: account.uniqueID)
        
        if let map = center.value(forKey: "_guidToTransferMap") as? NSDictionary {
            map.setValue(transfer, forKey: guid)
        }
        
        center.registerTransfer(withDaemon: guid)
        
        return transfer
    }
}

extension DBReader {
    func attachment(for guid: String) -> EventLoopFuture<InternalAttachmentRepresentation?> {
        let promise = eventLoop.makePromise(of: InternalAttachmentRepresentation?.self)
        
        do {
            try pool.read { db in
                guard let results = try RawAttachment.filter(RawAttachment.Columns.guid == guid).fetchOne(db) else {
                    promise.succeed(nil)
                    return
                }
                
                guard let guid = results.guid, let path = results.filename as NSString? else {
                    promise.succeed(nil)
                    return
                }
                
                promise.succeed(InternalAttachmentRepresentation(guid: guid, path: path.expandingTildeInPath, bytes: UInt64(results.total_bytes ?? 0), incoming: (results.is_outgoing ?? 0) == 0, mime: results.mime_type))
            }
        } catch {
            promise.fail(error)
        }
        
        return promise.futureResult
    }
}
